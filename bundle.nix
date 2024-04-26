{
  stdenv,
  writeClosure,
  writeTextFile,
}:
pkg: runCmd:
let
  baseRunScript = writeTextFile {
    name = "base-run";
    # Relies on host environment for:
    #   sh, tail, tar
    text = ''
      #!/usr/bin/env sh
      set -e
      tail -n +6 $0 | tar xzf - -P
      ${runCmd}
      exit $?
    '';
    executable = true;
  };
  toolsBundle = stdenv.mkDerivation {
    name = "tools-bundle";
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      tar czf $out -P -T ${writeClosure pkg}
    '';
  };
  runScript = stdenv.mkDerivation {
    name = "run";
    dontUnpack = true;
    dontBuild = true;
    dontPatchShebangs = true;
    installPhase = ''
      cat ${baseRunScript} ${toolsBundle} >> $out
      chmod +x $out
    '';
  };
in
runScript
