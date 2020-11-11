require! <[fs node-sass postcss-scss]>
ret = postcss-scss.parse(fs.read-file-sync 'config/default/_variables.scss' .toString!)
ret = ret.nodes
  .filter -> it.prop
  .map -> it{prop, value}
console.log ret
