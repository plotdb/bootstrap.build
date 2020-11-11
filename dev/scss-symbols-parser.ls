require! <[fs scss-symbols-parser]>

symbols = scss-symbols-parser.parse-symbols(fs.read-file-sync 'config/default/_variables.scss' .toString!)
variables = symbols.variables.map -> it{name, value}
console.log variables
#console.log symbols.variables.filter -> /primary/.exec(it.name)
