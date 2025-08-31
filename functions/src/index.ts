import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import vision from '@google-cloud/vision';

admin.initializeApp();
const client = new vision.ImageAnnotatorClient();

export const analyzeImage = onCall(async (request: any) => {
  try {
    const data = request.data as any;
    const path: string | undefined = data?.path;
    const modes = data?.modes ?? { object: true, label: true };
    if (!path || !path.startsWith('gs://')) {
      throw new HttpsError('invalid-argument', 'path (gs://) is required');
    }

    const image = { source: { imageUri: path } };
    const result: any = { objects: [], labels: [] };

    if (modes.object) {
      const [objRes] = await client.objectLocalization(image);
      const anns = objRes.localizedObjectAnnotations ?? [];
      result.objects = anns.map((o: any) => {
        const verts = o.boundingPoly?.normalizedVertices ?? [];
        const xs = verts.map((v: any) => v.x ?? 0);
        const ys = verts.map((v: any) => v.y ?? 0);
        const minX = Math.min(...xs), minY = Math.min(...ys);
        const maxX = Math.max(...xs), maxY = Math.max(...ys);
        return {
          name: o.name,
          score: o.score,
          bbox: { x: minX, y: minY, w: Math.max(0, maxX - minX), h: Math.max(0, maxY - minY) },
        };
      });
    }

    if (modes.label) {
      const [labRes] = await client.labelDetection(image);
      const labs = labRes.labelAnnotations ?? [];
      result.labels = labs.map((l: any) => ({
        description: l.description,
        score: l.score,
      }));
    }

    return result;
  } catch (e: any) {
    throw new HttpsError('internal', e?.message ?? String(e));
  }
});
