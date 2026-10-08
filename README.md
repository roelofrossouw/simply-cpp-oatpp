# simply-cpp-oatpp

Oatpp, built from its upstream source and repackaged for apt. It provides the
runtime package `simply-cpp-oatpp` and the headers/CMake package in
`simply-cpp-oatpp-dev`.

This lets simply-cpp modules such as `sc-rest-server` use oatpp as a normal
system dependency instead of compiling it as part of every consumer build.

## Publishing

This is an upstream source package, so it must be built separately on each
Ubuntu release:

```bash
scripts/deploy.sh
```

Set `VERSION.txt` to the upstream oatpp release tag before publishing.
