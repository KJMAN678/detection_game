import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const MY_SECRET = defineSecret("VISION_API_KEY");

export const callExternalApi = onCall(
  // 開発中は App Check を一時的に無効化（本番では true に戻す）
  { secrets: [MY_SECRET], enforceAppCheck: false },
  async (_req) => {
    const secretKey = MY_SECRET.value();
    // クライアントが利用する API キーを返す
    return { apiKey: secretKey };
  }
);
