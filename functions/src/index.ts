import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const VISION_API_KEY = defineSecret("VISION_API_KEY");

export const analyzeImage = onCall(
  { secrets: [VISION_API_KEY], enforceAppCheck: true },
  async (req) => {
    const apiKey = VISION_API_KEY.value();
    if (!apiKey) throw new Error("VISION_API_KEY is empty");
    const imageBase64: string = req.data?.imageBase64 ?? "";
    if (!imageBase64) throw new Error("imageBase64 required");

    // data:image/...;base64, を外す
    const content = imageBase64.replace(/^data:.*;base64,/, "");

    const body = { requests: [{ image: { content }, features: req.data?.features ?? [{ type: "LABEL_DETECTION", maxResults: 10 }] }] };

    const r = await fetch(`https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
    });
    if (!r.ok) throw new Error(`vision ${r.status}: ${await r.text()}`);
    return await r.json();
  }
);
