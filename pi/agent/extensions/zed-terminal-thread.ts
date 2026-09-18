import path from "node:path";
import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MAX_TITLE_LENGTH = 60;

function isZedTerminal(): boolean {
	return process.env.TERM_PROGRAM === "zed" || process.env.ZED_TERM === "true";
}

function normalizeTitle(text: string): string | undefined {
	const normalized = text
		.replace(/[\x00-\x1f\x7f]/g, " ")
		.replace(/\s+/g, " ")
		.trim();

	if (!normalized || normalized.startsWith("/")) return undefined;
	if (normalized.length <= MAX_TITLE_LENGTH) return normalized;

	const shortened = normalized.slice(0, MAX_TITLE_LENGTH - 1);
	const lastSpace = shortened.lastIndexOf(" ");
	return `${shortened.slice(0, lastSpace >= 35 ? lastSpace : undefined).trimEnd()}…`;
}

function firstUserPrompt(ctx: ExtensionContext): string | undefined {
	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type !== "message" || entry.message.role !== "user") continue;

		const content = entry.message.content;
		if (typeof content === "string") return content;
		if (Array.isArray(content)) {
			const text = content
				.filter((part): part is { type: "text"; text: string } =>
					part.type === "text" && typeof part.text === "string",
				)
				.map((part) => part.text)
				.join(" ");
			if (text) return text;
		}
	}
	return undefined;
}

export default function (pi: ExtensionAPI) {
	if (!isZedTerminal()) return;

	const fallbackTitle = `π · ${path.basename(process.cwd())}`;
	let active = true;

	function applyTitle(ctx: ExtensionContext, candidate?: string): void {
		const title = normalizeTitle(candidate ?? "") ?? fallbackTitle;
		ctx.ui.setTitle(title);
	}

	async function generateTitle(ctx: ExtensionContext, prompt: string): Promise<string | undefined> {
		const model = ctx.model;
		if (!model || !ctx.modelRegistry.hasConfiguredAuth(model)) return undefined;

		const response = await ctx.modelRegistry.complete(
			model,
			{
				messages: [
					{
						role: "user",
						content: [
							{
								type: "text",
								text: [
									"Write a concise title for this coding-agent task.",
									"Use 3 to 7 words, keep the user's language, and output only the title without quotes.",
									"",
									prompt.slice(0, 4000),
								].join("\n"),
							},
						],
						timestamp: Date.now(),
					},
				],
			},
			{
				reasoningEffort: "minimal",
				cacheRetention: "none",
				sessionId: uuidv7(),
			},
		);

		const text = response.content
			.filter((part): part is { type: "text"; text: string } => part.type === "text")
			.map((part) => part.text)
			.join(" ")
			.replace(/^["'`]+|["'`]+$/g, "");
		return normalizeTitle(text);
	}

	async function generateAndApplyTitle(
		ctx: ExtensionContext,
		prompt: string,
		expectedName: string,
	): Promise<void> {
		try {
			const title = await generateTitle(ctx, prompt);
			if (active && title && pi.getSessionName() === expectedName) {
				pi.setSessionName(title);
				applyTitle(ctx, title);
			}
		} catch (error) {
			if (!active) return;
			const message = error instanceof Error ? error.message : String(error);
			ctx.ui.notify(`Impossible de générer le titre : ${message}`, "warning");
		}
	}

	pi.on("session_start", (_event, ctx) => {
		const prompt = firstUserPrompt(ctx);
		const provisionalTitle = normalizeTitle(prompt ?? "");
		let name = pi.getSessionName();

		if (!name && provisionalTitle) {
			name = provisionalTitle;
			pi.setSessionName(name);
		}
		applyTitle(ctx, name);

		// On reload, replace a title previously derived verbatim from the first
		// prompt. Explicitly named sessions are left untouched.
		if (prompt && name && name === provisionalTitle) {
			void generateAndApplyTitle(ctx, prompt, name);
		}
	});

	pi.on("input", (event, ctx) => {
		if (!pi.getSessionName() && event.source === "interactive") {
			const name = normalizeTitle(event.text);
			if (name) {
				pi.setSessionName(name);
				applyTitle(ctx, name);
				void generateAndApplyTitle(ctx, event.text, name);
			}
		}
		return { action: "continue" };
	});

	pi.on("session_info_changed", (event, ctx) => {
		applyTitle(ctx, event.name);
	});

	// Zed turns a terminal bell into a Terminal Thread notification whenever
	// the thread is not focused.
	pi.on("agent_settled", () => {
		process.stdout.write("\x07");
	});

	pi.on("session_shutdown", () => {
		active = false;
	});

	// Also request attention when an extension opens a blocking prompt.
	pi.on("ui_prompt_start", () => {
		process.stdout.write("\x07");
	});
}
