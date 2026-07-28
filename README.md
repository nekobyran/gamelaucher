# GameLauncher Private Preview

Private preview release metadata and the production static release site for GameLauncher.

- Production domain: `gamelaucher.nkbr.cc`
- Cloudflare Pages project: `nkbr-gamelaucher`
- Hosting model: static assets only; no Pages Functions
- Downloads: private GitHub Releases; invited GitHub accounts must sign in

## Local validation

```powershell
node tools/validate-site.mjs
./command/Publish-StaticReleaseSite.ps1 -Action Build
node tools/serve.mjs ..\..\release\gamelaucher_web\release 4173
```

## Deployment

```powershell
./command/Publish-StaticReleaseSite.ps1 -Action WhoAmI
./command/Publish-StaticReleaseSite.ps1 -Action Deploy
```

Domain binding is intentionally separate. The process or CI environment must already provide `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, then run:

```powershell
./command/Publish-StaticReleaseSite.ps1 -Action BindDomain
```

Never commit `.env`, API tokens, account credentials, downloaded release binaries, `node_modules`, or generated build output. Release binaries and diagnostic recordings remain GitHub Release assets rather than Git objects. `RELEASE_NOTES.md` defines the verified scope and known limitations.
