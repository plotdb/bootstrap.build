require! <[fs fs-extra path yargs node-sass clean-css scss-symbols-parser @plotdb/colors]>

argv = yargs
  .option \config, do
    alias: \c
    description: "dir for custom _custom.scss and other scss files"
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

if fs.exists-sync path.join(vardir, '_variables.scss') =>
  console.log "[warning] since 0.0.7, we use `_custom.scss` instead of `_variables.scss` unless you want to overwrite the default `_variables.scss` file completely, which is unlikely to happen.".yellow


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

twbs-root = twbs-root.0
origin-varfile = path.join(twbs-root, "scss/_variables.scss")

console.log "found bootstrap in #twbs-root. "

varfile = path.join(vardir, "_custom.scss")

fs-extra.ensure-dir-sync path.join(outdir, \css)
fs-extra.ensure-dir-sync vardir
if !fs.exists-sync(varfile) => fs-extra.copy-sync origin-varfile, varfile

files.map (fn) ->
  console.log "build #fn ..."
  code = """
  @import "#{varfile}";
  @import "#{fn}";
  """
  code = node-sass.render-sync {
    data: code
    includePaths: [vardir, path.join(twbs-root,\scss)]
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
  fs.write-file-sync path.join(outdir, \css, fn.replace(\scss, \css)), code.css
  fs.write-file-sync path.join(outdir, \css, fn.replace(\scss, \min.css)), code-min.styles

console.log "generating json for variables ..."
variables = (
  scss-symbols-parser.parse-symbols(fs.read-file-sync origin-varfile .toString!).variables ++
  scss-symbols-parser.parse-symbols(fs.read-file-sync varfile .toString!).variables
).map -> it{name,value}
fs.write-file-sync path.join(outdir, \css, "variables.json"), JSON.stringify(variables)
