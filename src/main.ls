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

origin-varfile = path.join(__dirname, "..", "node_modules/bootstrap/scss/_variables.scss")
if fs.exists-sync origin-varfile => fs.rename-sync origin-varfile, (origin-varfile + ".original")
else if !fs.exists-sync(origin-varfile + ".original") =>
  if fs.exists-sync "node_modules/bootstrap/scss/_variables.css" =>
    origin-varfile = "node_modules/bootstrap/scss/_variables.css"
    fs.rename-sync origin-varfile, (origin-varfile + ".original")
  else if !fs.exists-sync("node_modules/bootstrap/scss/_variables.css.original") =>
    console.log "can't locate bootstrap module folder. did you install bootstrap?"
    process.exit -1
  origin-varfile = "node_modules/bootstrap/scss/_variables.css.original"

origin-varfile = origin-varfile + ".original"

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

