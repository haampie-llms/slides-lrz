#!/usr/bin/env python3
"""Append N tiny layers to an OCI layout image (to probe container runtime layer limits).
Usage: many_layers.py <oci-dir> <n>   (oci-dir created with `skopeo copy docker://... oci:<dir>`)"""
import gzip, hashlib, io, json, os, sys, tarfile

d, n = sys.argv[1], int(sys.argv[2])
blobs = os.path.join(d, "blobs", "sha256")
def put(data):
    h = hashlib.sha256(data).hexdigest()
    with open(os.path.join(blobs, h), "wb") as f:
        f.write(data)
    return h
def get(digest):
    with open(os.path.join(blobs, digest.split(":")[1]), "rb") as f:
        return f.read()

index = json.loads(open(os.path.join(d, "index.json")).read())
manifest = json.loads(get(index["manifests"][0]["digest"]))
config = json.loads(get(manifest["config"]["digest"]))
for i in range(n):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.PAX_FORMAT) as tar:
        data = f"layer {i}\n".encode()
        info = tarfile.TarInfo(f"layers/{i:04d}.txt"); info.size = len(data); info.mtime = 0
        tar.addfile(info, io.BytesIO(data))
    raw = buf.getvalue()
    gz = gzip.compress(raw, mtime=0)
    h = put(gz)
    manifest["layers"].append({"mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
                               "digest": f"sha256:{h}", "size": len(gz)})
    config["rootfs"]["diff_ids"].append("sha256:" + hashlib.sha256(raw).hexdigest())
cfg = json.dumps(config).encode()
manifest["config"]["digest"] = "sha256:" + put(cfg); manifest["config"]["size"] = len(cfg)
man = json.dumps(manifest).encode()
index["manifests"][0].update(digest="sha256:" + put(man), size=len(man))
open(os.path.join(d, "index.json"), "w").write(json.dumps(index))
print(f"{len(manifest['layers'])} layers")
