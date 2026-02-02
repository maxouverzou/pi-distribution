import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

interface AuthJson {
  [key: string]: {
    type: string;
    access?: string;
    refresh?: string;
    expires?: number;
    projectId?: string;
  };
}

export default function (pi: ExtensionAPI) {
  const handler = async (args: string, ctx: any) => {
    const authPath = path.join(os.homedir(), ".pi/agent/auth.json");
    let auth: AuthJson = {};
    try {
      if (fs.existsSync(authPath)) {
        auth = JSON.parse(fs.readFileSync(authPath, "utf-8"));
      }
    } catch (e) {
      ctx.ui.notify("Failed to read auth.json", "error");
    }

    ctx.ui.setStatus("limits", "Fetching limits...");
    
    const results: string[] = [];

    // Gemini
    if (auth["google-gemini-cli"]) {
      const gemini = auth["google-gemini-cli"];
      try {
        const res = await fetchGeminiUsage(gemini.access!);
        if (res) {
          results.push(...res);
        }
      } catch (e) {
        results.push("Gemini: Error fetching usage");
      }
    }

    // Copilot
    if (auth["github-copilot"]) {
      const copilot = auth["github-copilot"];
      const token = copilot.refresh || copilot.access;
      if (token) {
        try {
          const res = await fetchCopilotUsage(token);
          if (res) {
            results.push(...res);
          }
        } catch (e) {
          results.push("GitHub Copilot: Error fetching usage");
        }
      }
    }

    if (results.length === 0) {
      ctx.ui.notify("No subscriptions found in auth.json", "warning");
    } else {
      ctx.ui.setWidget("limits", results, { placement: "belowEditor" });
      setTimeout(() => ctx.ui.setWidget("limits", undefined), 10000);
    }
    
    ctx.ui.setStatus("limits", undefined);
  };

  pi.registerCommand("limits", {
    description: "Show AI subscription limits and usage",
    handler,
  });

  pi.registerCommand("usage", {
    description: "Show AI subscription limits and usage (alias for /limits)",
    handler,
  });

  async function fetchGeminiUsage(accessToken: string): Promise<string[] | null> {
    const headers = {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    };

    // Step 1: Get project ID
    const loadRes = await fetch("https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist", {
      method: "POST",
      headers,
      body: JSON.stringify({
        metadata: {
          ideType: "IDE_UNSPECIFIED",
          platform: "PLATFORM_UNSPECIFIED",
          pluginType: "GEMINI"
        }
      })
    });

    if (!loadRes.ok) return ["Gemini: Auth failed"];
    const loadData = await loadRes.json() as any;
    const projectId = loadData.cloudaicompanionProject;
    const tier = loadData.currentTier?.name || "unknown";

    if (!projectId) return [`Gemini: Connected (Tier: ${tier}), but no project ID`];

    // Step 2: Get quota
    const quotaRes = await fetch("https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota", {
      method: "POST",
      headers,
      body: JSON.stringify({ project: projectId })
    });

    if (!quotaRes.ok) return [`Gemini: Connected (Tier: ${tier}), but failed to fetch quota`];
    const quotaData = await quotaRes.json() as any;
    
    const lines: string[] = [`Gemini (${tier}):`];
    const buckets = quotaData.buckets || [];
    
    // Tiers
    const GEMINI_TIERS: Record<string, string> = {
        "gemini-3-flash-preview": "3-Flash",
        "gemini-2.5-flash": "Flash",
        "gemini-2.5-flash-lite": "Flash",
        "gemini-2.0-flash": "Flash",
        "gemini-2.5-pro": "Pro",
        "gemini-3-pro-preview": "Pro",
    };

    const seenModels = new Set<string>();
    for (const bucket of buckets) {
      const modelId = bucket.modelId;
      if (seenModels.has(modelId)) continue;
      
      const remaining = bucket.remainingFraction;
      const used = (1 - remaining) * 100;
      let line = `  ${modelId.padEnd(30)} ${used.toFixed(1).padStart(5)}%`;
      
      if (bucket.resetTime) {
        const resetsIn = formatResetTime(bucket.resetTime);
        line += ` (Resets in ${resetsIn})`;
      }
      
      lines.push(line);
      seenModels.add(modelId);
    }

    return lines;
  }

  async function fetchCopilotUsage(token: string): Promise<string[] | null> {
    try {
      const res = await fetch("https://api.github.com/copilot_internal/user", {
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!res.ok) {
        return [`GitHub Copilot: Auth failed (${res.status})`];
      }

      const data = await res.json() as any;
      const lines: string[] = [`GitHub Copilot (${data.copilot_plan}):`];

      if (data.quota_snapshots?.premium_interactions) {
        const premium = data.quota_snapshots.premium_interactions;
        const used = premium.entitlement - premium.remaining;
        const total = premium.entitlement;
        
        let line = `  Premium Interactions: ${used}/${total}`;
        if (total > 0) {
          const percent = (used / total) * 100;
          line += ` (${percent.toFixed(1)}%)`;
        }
        
        if (data.quota_reset_date_utc) {
          const reset = new Date(data.quota_reset_date_utc);
          line += ` (Resets: ${reset.toLocaleDateString()} ${reset.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })})`;
        }
        lines.push(line);
      } else {
        lines.push("  Quota info not available");
      }

      return lines;
    } catch (e) {
      return ["GitHub Copilot: Error fetching usage"];
    }
  }

  function formatResetTime(isoTime: string): string {
    try {
      const resetDate = new Date(isoTime);
      const now = new Date();
      const diffMs = resetDate.getTime() - now.getTime();
      
      if (diffMs <= 0) return "now";
      
      const hours = Math.floor(diffMs / (1000 * 60 * 60));
      const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
      
      if (hours > 0) return `${hours}h ${minutes}m`;
      return `${minutes}m`;
    } catch (e) {
      return isoTime;
    }
  }
}
