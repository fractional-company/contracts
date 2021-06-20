## Building 

### MacOS Big Sur (ARM64)

Pull submodules:
```
git submodule update --init
```

Install Rosetta:
```
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

Install Nix:
```
sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume
```

Install dapp:
```
curl https://dapp.tools/install | sh
```

Install solc:0.8.0:
```
nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_0
```

Test
```
make test
```