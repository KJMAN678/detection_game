# Firebase Functions for Detection Game

- Callable: `analyzeImage`
- Input: `{ path: "gs://<bucket>/<path>.jpg", modes: { object: boolean, label: boolean } }`
- Output:
```
{
  "objects": [{ "name": "Person", "score": 0.92, "bbox": { "x":0.1,"y":0.2,"w":0.3,"h":0.4 } }],
  "labels": [{ "description": "Dog", "score": 0.88 }]
}
```

Enable Cloud Vision API and billing. Deploy with Node.js 20+. Do not store secrets in repo.
