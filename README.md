MediaWiki Discourse extension
=============================

See [mediawiki.org/wiki/Extension:Discourse](https://www.mediawiki.org/wiki/Extension:Discourse)
for all information.

## Configuration

This extension provides a Lua library with the following functions:

* `discourse.getData( site, urlPath )` — Get data from a Discourse site.
  * `@param string site` Site name, from $wgDiscourseSites.
  * `@param string urlPath` The URL path of a JSON endpoint.
  * `@return table` Whatever is returned by the Discourse API.
* `discourse.getBaseUrl( site )` — Get the base URL of a given Discourse site.
  * `@param string site` Site name, from $wgDiscourseSites.
  * `@return table` With 'result' key.

The library also provides two example functions that can be used as-is or serve as the basis for a wiki's own formatting etc.
A [[Module:Discourse]] that uses these could look something like the following:

```
local discourse = require( 'mw.ext.discourse' )

function news( frame )
    return discourse.news( frame )
end

function events( frame )
    return discourse.events( frame )
end

return {
    news = function( frame ) return news( frame ) end;
    events = function( frame ) return events( frame ) end;
}

-- Debugging:
-- =p.news({args={site='space'}})
-- =p.news({args={tags='wikisource'}})
```
