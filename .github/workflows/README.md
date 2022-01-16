# Godot exportation and Publishing

Based on blog https://github.com/dsaltares/godot-wild-jam-18:
- [publish_github.yml](publish_github.yml) allowq to export the Stigmee project (made in Godot-3.4) and publish the release on the GitHub page.
- [publish_itch.yml](publish_itch.yml) fecth the Stigmee release published on GitHub (thru publish_github.yml) and publish it on itchi.io

## Needed tokens

- `EXPORT_GITHUB_TOKEN` holding your personal GitHub workflow secret allowing you to trigger GitHub actions.
- `ACCESS_TOKEN` holding your personal GitHub repo secret to give you the right to git cloning on private repos inside the Stigmee organisation.
- `BUTLER_CREDENTIALS` holding your personal https://itch.io/ API key (worked but currently disabled).

Read this [internal document](https://github.com/stigmee/doc-internal/blob/master/doc/continuous_deployment_en.md) for more information concerning
GitHub actions for Stigmee and the needed tokens.

## Readings

See https://youtu.be/R8_veQiYBjI for an introduction to GitHub actions.
