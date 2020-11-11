require! <[fs fs-extra path yargs node-sass clean-css]>

argv = yargs
  .option \config, do
    alias: \c
    description: "dir for custom _variables.scss"
    type: \string
  .option \output, do
    alias: \o
    description: "output directory. default dist, if omitted."
    type: \string
  .help \help
  .alias \help, \h
  .check (argv, options) ->
    if !argv.c or !fs.exists-sync(argv.c) => throw new Error("config file directory missing.")
    return true
  .argv

vardir = argv.c
files = <[bootstrap.scss bootstrap-grid.scss bootstrap-reboot.scss]>
outdir = if argv.o? => argv.o else \dist


twbs-roots = [
  "node_modules/bootstrap"
  path.join(__dirname, "..", "node_modules/bootstrap")
]

twbs-root = twbs-roots
  .map (p) ->
    f1 = fs.exists-sync path.join(p, "scss/_variables.scss")
    f2 = fs.exists-sync path.join(p, "scss/_variables.scss.original")
    return [p, f1, f2]
  .filter (b) -> b.1 or b.2
  .0

if !twbs-root =>
  console.log "can't locate bootstrap module folder. did you install bootstrap?"
  process.exit -1

if twbs-root.1 =>
  fs.rename-sync(
    path.join(twbs-root.0, "scss/_variables.scss"),
    path.join(twbs-root.0, "scss/_variables.scss.original")
  )

twbs-root = twbs-root.0
origin-varfile = path.join(twbs-root, "scss/_variables.scss.original")

console.log "found bootstrap in #twbs-root]. "

/*
origin-varfile = path.join(__dirname, "..", "node_modules/bootstrap/scss/_variables.scss")
if fs.exists-sync origin-varfile => fs.rename-sync origin-varfile, (origin-varfile + ".original")
else if !fs.exists-sync(origin-varfile + ".original") =>
  if fs.exists-sync "node_modules/bootstrap/scss/_variables.scss" =>
    origin-varfile = "node_modules/bootstrap/scss/_variables.scss"
    fs.rename-sync origin-varfile, (origin-varfile + ".original")
  else if !fs.exists-sync("node_modules/bootstrap/scss/_variables.scss.original") =>
    console.log "can't locate bootstrap module folder. did you install bootstrap?"
    process.exit -1
  origin-varfile = "node_modules/bootstrap/scss/_variables.scss.original"
origin-varfile = origin-varfile + ".original"
*/

varfile = path.join(vardir, "_variables.scss")

fs-extra.ensure-dir-sync outdir
fs-extra.ensure-dir-sync vardir
if !fs.exists-sync(varfile) => fs-extra.copy-sync origin-varfile, varfile

files.map (fn) ->
  console.log "build #fn ..."
  code = node-sass.render-sync {
    file: path.join(__dirname, "..", "node_modules/bootstrap/scss", fn)
    includePaths: [vardir]
    outputStyle: \expanded
    sourceMap: true
    sourceMapContents: true
    precision: 6
  }
  code-min = new clean-css({
    level: 1
    format: { breakWith: \lf }
    sourceMap: true
    sourceMapInlineSources: true
  }).minify(code.css)
  fs.write-file-sync path.join(outdir, fn.replace("scss","css")), code.css
  fs.write-file-sync path.join(outdir, fn.replace("scss","min.css")), code-min.styles

