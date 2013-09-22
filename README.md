# GitHubReminder

https://githubreminder.org/

A serendipitous email reminder
for your starred repos on GitHub.

## Dependencies

The server-side code
depends on
[Node.js][node],
[NPM],
[CoffeeScript],
[Hapi],
[MongoDB],
[Handlebars],
[Nodemailer],
[node-uuid][uuid],
[Underscore.js][underscore],
[pub-sub.js][pubsub] and
[check-types.js][checktypes].

Assuming that you already have
node and npm installed,
you can install the remaining dependencies
by running `npm install`
from the project root.

## Build environment

The build enviroment
has further dependencies on
[UglifyJS],
[Stylus],
[autoprefixer] and
[clean-css].
Again, those will be taken care of
by `npm install`.

There are no tests at the moment
and no proper build system either.
I'm just abusing `npm run`
for a bunch of build targets right now
but will likely update to something
more suitable in due course
(not Grunt though,
I bloody hate Grunt).

### Back-end build target

There is one build target
for the back-end.
It compiles `server/index.coffee`
to `server/index.js`
so that the site can run
when deployed to production
(where CoffeeScript is not available globally).

You can invoke this target with:

```
npm run build-back
```

### Front-end build targets

There are a couple of front-end build targets,
responsible for compiling
the client-side CoffeeScript to JavaScript
and Stylus to CSS.

You can invoke both of those targets together with:

```
npm run build-front
```

Or you can reduce the workload
by targeting just the CoffeeScript:

```
npm run build-coffee-front
```

Or Stylus:

```
npm run build-css
```

### Source code structure

There's not a huge amount of code
so it should be pretty straightforward to grok.
But fwiw:

```
server/index.coffee - server-side bootstrap module
server/index.js - server-side bootstrap module (generated code)

serer/eventBroker.coffee - pub/sub implementation used to decouple server-side modules
server/events.coffee - event definitions for pub/sub

server/github.coffee - GitHub API abstraction
server/database.coffee - MongoDB abstraction
server/jobs.coffee - scheduler
server/email/*.coffee - email composition and dispatch
server/tokens.coffee - unique ids
server/templates.coffee - Handlebars helpers
server/errors.coffee - universal error handler
server/log.coffee - logging
server/retrier.coffee - conditional and repeated function invocation

server/routes - route definitions
server/routes/helpers - assorted boilerplate abstractions to simplify routes

config/index.coffee - private configuration data (hidden in private submodule)
config.local/index.coffee - skeleton configuration data for local usage

views/layout.html - layout template
views/content/*.html - body content templates

client/src - client-side CoffeeScript
client/lib - client-side JavaScript (generated code, unminified)
public/lib - client-side JavaScript (generated code, minified)

client/style - Stylus
public/style - CSS (generated code, minified)
```

## Contributions

All bug fixes
and back-end improvements
(especially those of a functional bent)
will be gratefully received.
Styling changes to the front-end
may be less likely to get accepted,
it rather depends on planetary alignment
and which side of bed I got out of.

## License

[MIT][license]

[node]: http://nodejs.org/
[npm]: https://npmjs.org/
[coffeescript]: http://coffeescript.org/
[hapi]: http://spumko.github.io/
[mongodb]: http://www.mongodb.org/
[handlebars]: http://handlebarsjs.com/
[nodemailer]: https://github.com/andris9/Nodemailer
[uuid]: https://github.com/shtylman/node-uuid
[underscore]: http://underscorejs.org/
[pubsub]: https://github.com/philbooth/pub-sub.js
[checktypes]: https://github.com/philbooth/check-types.js
[uglifyjs]: https://github.com/mishoo/UglifyJS
[stylus]: http://learnboost.github.io/stylus
[autoprefixer]: https://github.com/ai/autoprefixer
[clean-css]: https://github.com/GoalSmashers/clean-css
[license]: https://github.com/philbooth/GitHubReminder/blob/master/COPYING

