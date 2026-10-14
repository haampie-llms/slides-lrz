# Sharing software environments with Spack — from `spack.yaml` to container images

LRZ, 15 Oct 2026 · Harmen Stoppels (Spack maintainer, volunteer) · 90 min

## The thread running through the talk

Every way of sharing sits somewhere on a spectrum, and the question is the same each time:
**what do you assume the other machine already has?**

```
 spack.yaml  →  spack.lock  →  build cache  →  container image
 (intent)       (decisions)    (binaries)      (binaries + OS userland)
 most flexible ─────────────────────────────── least assumptions about the target
```

The recurring answer: **externals**. glibc is *always* an external. Every step to the right
moves one more thing from "assumed on the target" to "shipped with the artifact".

Second thread, set up in part 2 and paid off in part 3: **a container image is just an archive**
(a manifest that points at tarballs, plus a JSON config). Building one by running commands
*inside* a container and snapshotting the result is one way to make one, not the definition.

---

## 0. Opening (≈5 min)

- Who I am, what Spack is, in one slide (most people in the room know it already).
- What "sharing an environment" means: with a colleague, from a laptop to a cluster, from CI
  to users, from one cluster to the next.
- The spectrum slide above, which also serves as the agenda.

## 1. Spack environments and how far they travel (≈25 min)

**1.1 Recap of environments (quick)**
- `spack.yaml` lists abstract specs plus config (packages, mirrors, concretizer options).
- `spack.lock` holds the fully concrete DAG: every node, variant and hash.
- `spack env create myenv spack.yaml` re-concretizes; `spack env create myenv spack.lock`
  reproduces the DAG exactly.

**1.2 Sharing `spack.yaml`: portable, but you get a different answer**
- Different Spack version, package repo commit, compilers and externals mean a different DAG.
- Good for "same software, appropriate for this machine". Bad for "exactly what I ran".
- Pin what matters: the `spack-packages` repo commit, `require:`, `concretizer:unify`.

**1.3 Sharing `spack.lock`: exact, until the machine leaks in**
- Live: `spack spec -L zlib-ng`, showing `[e] gcc@13.3.0` and `[e] glibc@2.39` as nodes in the DAG.
- Externals are part of the hash and record a prefix (`/usr`). On another machine they may not
  exist, may sit at a different path, or may be a different version.
- Typical externals on HPC systems: system compiler, **glibc (always)**, vendor MPI,
  CUDA/oneAPI, Slurm/PMIx, libfabric/UCX.

**1.4 libc is the one external you can't avoid**
- Since Spack v1.0, glibc is an explicit node in the DAG.
- The concretizer only reuses a binary when its libc is compatible with the host: built against
  glibc X, it runs where glibc ≥ X. The rule is in `solver/libc_compatibility.lp`.
- Practical rule: **build on the oldest glibc you need to support**.
- The CPU target is another implicit assumption: `target=zen2` will not run on older CPUs. Use
  `packages: all: require: target=x86_64_v3` (or similar) for shared binaries.

**1.5 Moving the bits: build caches**
- `spack mirror add`, `spack buildcache push`, `spack install` (reuse binaries before building).
- Relocation: binaries contain absolute paths that Spack rewrites on install, which is why
  `install_tree: padded_length` matters.
- Signing (`spack gpg`) versus `--unsigned`, and `--update-index` (the tutorial covers neither).
- Air-gapped or offline targets: filesystem mirrors, `spack mirror create`.
- Takeaway: lockfile plus build cache equals "the same binaries, installed by Spack, on a
  compatible host".

**1.6 Patterns for keeping environments shareable**
- Keep site specifics (externals, compilers, modules) out of `spack.yaml`, in an included
  site config scope.
- Prefer Spack-built over external where it is cheap; keep externals where they must match the
  host (MPI, drivers, Slurm).
- Where it still hurts: anything that has to match the host kernel or driver (MPI fabric, GPU
  driver). This leads into containers, which do *not* solve it either.

**1.7 Other points on the same spectrum (brief, ≈2 min)**
- CVMFS/EESSI-style stacks ship their *own* libc in a compatibility layer, which removes the
  glibc external at the cost of a dedicated filesystem/client.
- Conda ships everything except glibc (a minimum glibc via `__glibc`), so it makes the same
  assumption Spack does.
- Spack composes well with both: a site stack as an upstream, plus a user environment or build
  cache on top.
- Use case: short-lived or virtual clusters (cloud VMs, CI runners) re-create the same
  environment over and over. A shared build cache turns "rebuild the stack" into "fetch
  binaries".

## 2. Containers from the inside out: `spack containerize` (≈20 min)

**2.1 What a container image actually is (the foundation for parts 2 and 3)**
- Image index → manifest → config (Env, Entrypoint, `rootfs.diff_ids`) and a list of layer
  tarballs. That is all.
- Live: `skopeo inspect --raw docker://ubuntu:24.04 | jq`, then `skopeo inspect --config`.
- A runtime unpacks the tarballs, stacks them (overlayfs, or flattened into a squashfs or
  SIF), and runs a process with the config's environment.
- A `Dockerfile` is one way to *produce* such an archive: run a command in a container,
  snapshot the diff as a tarball, append it to the manifest. It is not the only way.

**2.2 `spack containerize`**
- Add a `container:` section to `spack.yaml` and run `spack containerize > Dockerfile`, or
  `format: singularity` for a `.def` file.
- Walk through the generated multi-stage Dockerfile: the build stage runs `spack/ubuntu-noble`
  and `spack install`, the binaries are stripped, `activate.sh` is generated, the final stage
  copies `/opt/software` and `/opt/views` onto a bare OS image, and an entrypoint sources the
  environment.
- Knobs: `images:` (os+spack, or custom `build`/`final`, e.g. a CUDA base image with CUDA as an
  external), `os_packages`, `strip`, `labels`, `depfile: true`, Jinja template extension.

**2.3 Pros**
- The build environment *is* the base image, so externals and glibc are fully under control
  (the part 1 problem largely goes away).
- A self-contained, reviewable recipe that standard tooling and CI understand. The Singularity
  output fits HPC.
- Spack is not needed on the target; you can add OS packages, files and users.

**2.4 Cons**
- Needs a build tool (Docker/Podman/Buildah/Apptainer) and often root or fakeroot, which
  usually means not on an HPC login node.
- `spack install` runs as one `RUN` step. Any change to `spack.yaml` invalidates the cache and
  rebuilds everything, and a failure discards all completed dependencies.
- Debugging failed builds inside a container build is painful.
- The output is one fat layer: no sharing between images that overlap.
- Binaries built inside the image don't flow back to anyone else unless you add a build cache.
- Mitigation and hybrid: give the Dockerfile a build cache (mirror in `spack.yaml`, or
  `RUN --mount=type=cache`), so most of the "build" becomes fetching binaries.

## 3. Containers as an archive: `spack buildcache push --base-image` (≈20 min)

**3.1 The key observation**
- A Spack build cache tarball of one package is already a valid OCI layer: entries are the
  absolute install path without the leading `/`, so it extracts to the same prefix.
- So the registry stores the *same blob* for two purposes:
  1. **`spack install`**: a build cache. The spec metadata lives in the image config, and the
     binaries are relocated on install.
  2. **`docker run`**: a runnable image. Paths are identical to the build host, so nothing
     needs relocating.
- No Dockerfile, no daemon, no root: only HTTP PUTs to a registry. It works from a login node
  or a laptop.

**3.2 What `buildcache push` assembles (from the implementation)**
- One layer per package, covering link and run dependencies only.
- **Externals are skipped**, so the base image has to supply them (glibc ≥ the build host's).
  This is the same thread as part 1: `--base-image` *is* your answer to "what does the target
  machine have?"
- The base image's layers are copied into the target registry first, then Spack's layers are
  appended.
- The config's `Env` is computed from Spack's own environment modifications (`PATH`, …). There
  is no view; every package sits at its own prefix.
- The Docker vs OCI manifest media type is matched to the base image, because Apptainer is
  strict about mixing the two.
- Every spec gets a tag `name-version-hash.spack`, and `--tag` names the whole set
  (environment).
- Live: `skopeo inspect` of a Spack-pushed image, showing the layer list next to `spack find -l`.

**3.3 Consequences**
- Deduplication: images that share dependencies share layers, in the registry and in a
  runtime's local store. Pushing an updated environment uploads only the changed packages.
- Layers are independent (not "each RUN on top of the previous one"), so any subset of
  packages makes a valid image.
- Reproducibility is as good as the host build: the reverse of the `containerize`
  trade-off.

**3.4 Limitations and how to deal with them**
- **Layer limit.** Docker's layer store caps an image at **125 layers**: 127 lowerdirs in some
  graph drivers, minus 2 for the init and read-write layers. Base image layers count too, and
  the error is `max depth exceeded`. Large environments (MPI and Python stacks easily reach 150+
  packages) hit this. Spack's docs say 128, which is slightly off.
  - Why: overlayfs stacks one lowerdir per layer.
  - Work-arounds: split into several smaller images; use a runtime that flattens layers
    (Apptainer → SIF, Charliecloud, Enroot → squashfs); or squash/flatten into one layer
    afterwards (losing deduplication).
- Install paths leak into the image (`/home/me/spack/opt/spack/...`). Use a neutral
  `install_tree: root: /opt/spack` with padding.
- No view and no entrypoint script: `PATH` grows with the number of packages.
- The image is host-dependent: build on an old glibc and a generic target.
- Customization (users, files, `ENTRYPOINT`) needs a thin `Dockerfile` with
  `FROM <spack-pushed-image>`. That is the hybrid of parts 2 and 3.
- One architecture per tag (no multi-arch index).
- Pushing needs network access to a registry. On firewalled systems, push from a
  build host or CI, or go through an SSH-tunnelled proxy (`https_proxy`). For fully offline
  systems, use filesystem build caches.

**3.4b Running Spack-pushed images on HPC runtimes**
- Docker, Podman and containerd (Kubernetes, JupyterHub) stack layers with overlayfs, so the
  layer limit matters there. Spack layers are shared across images on a node.
- Apptainer (`apptainer pull docker://…` → SIF), Enroot (`enroot import docker://…` →
  squashfs) and Charliecloud (`ch-image pull`, flattened directory) all **flatten** the layers,
  so the 125-layer limit doesn't apply to running there, only to the registry/Docker side.
- Spack matches the base image's manifest media type so that Apptainer accepts the image.
- Glibc example: binaries built on Ubuntu 24.04 (glibc 2.39) won't run natively on a SLES 15
  host (glibc 2.31), but they do run in an image whose base is ≥ 2.39. Containers move the
  libc assumption into the base image.
- MPI aside: inside-out images (part 2) and archived images (part 3) have the same problem.
  The container's MPI must be ABI-compatible with the host fabric/launcher: either bind-mount
  host MPI (MPICH ABI) or make the MPI an *external* that the base image provides.

**3.5 Choosing between them**
- A comparison table: containerize vs buildcache push across privileges, speed,
  reproducibility, layer reuse, customization and where builds get debugged.
- Rule of thumb: build where debugging is easy (host or CI with a build cache), *archive* into
  images, and only use a Dockerfile for what genuinely needs to run inside.

## 4. Hands-on: Spack tutorial, binary cache section (≈20–25 min)

- Follows <https://spack-tutorial.readthedocs.io> "Binary Caches" (Spack `releases/v1.2`, the
  `ghcr.io/spack/tutorial` container): install julia from a cache, a local OCI registry,
  `--base-image`, `--tag` for environments.
- Parts 1–3 give the *why*; the tutorial gives the *how*. Point back to the 125-layer limit and
  the glibc rule when they come up.

## 5. Wrap-up and Q&A (≈5–10 min)

- The spectrum slide again, annotated with "what you assume on the target" at each step.
- Pointers: docs (Containers, Build Caches), tutorial, Slack.

---

### Open questions for you
1. Live demos or recorded/terminal-output slides? Docker isn't usable here (no daemon access),
   but `skopeo` works without a daemon, and I can try a rootless registry and rootless Docker
   to capture real outputs.
2. Does the tutorial run as a real hands-on (participants with accounts or containers) or as a
   walkthrough?
3. MPI/GPU in containers: I added a short aside (3.4b). Keep it, expand it, or drop it?
4. Several facts to double-check before they go on a slide:
   - SLES 15's glibc version (I believe 2.31 through SP6).
   - Whether the containerd/Podman overlay snapshotters have the same ~125 limit as Docker's
     layer store. I only checked moby: `maxLayerDepth = 125` in
     `daemon/internal/layer/layer_store.go`, and overlay2 `maxDepth = 128`.
