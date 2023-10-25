# bootstrap.build

wrapper for building bootstrap with custom configuration.


## Usage

1. install:

    npm install --save-dev github:plotdb/bootstrap.build


2. prepare config file. you only need to provide difference part of bootstrap's `_custom.scss`, such as:

    $btn-padding-y:         .25rem;

   you can also provide additional scss files to overwrite files with the same names in bootstrap's scss folder.

3. name above config as `_custom.scss` and put it in desired folder.
4. run following:

    npx bootstrap.build -c config/default/ -o web/static/assets/lib/bootstrap.custom

5. you can also add above command in your `package.json` file:

    "scripts": {
      "bootstrap": "npx bootstrap.build -c config/default/ -o web/static/assets/lib/bootstrap.custom"
    }

## License

MIT
