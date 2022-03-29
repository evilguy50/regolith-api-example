# standard lib imports
import strformat, strutils, json, os, httpClient, asyncdispatch
# other imports
import nimbler

type
    Filter = object
        name: string
        url: string

proc newFilter(name: string, url: string): Filter=
    result.name = name
    result.url = url

proc getFilters(): seq[Filter]=
    os.createDir("./tmp")
    let topicUrl = """https://api.github.com/search/repositories?q=topic:regolith-filter"""
    let cli = newAsyncHttpClient()
    let resp = waitFor cli.getContent(topicUrl)
    let respJson = resp.parseJson()
    let root = os.getCurrentDir()
    os.setCurrentDir("./tmp")
    for repo in respJson["items"]:
        let url = $repo["clone_url"]
        let repoName = replace($repo["name"], "\"", "")
        discard os.execShellCmd(fmt"git clone --depth=1 {url}")
        echo url
        os.removeDir(fmt"./{repoName}/.git")
        for filter in os.walkDirs(fmt"./{repoName}/*"):
            let filterName = filter.splitPath()[1]
            let filterUrl = url.split("://")[1].replace(".git", "") & "/" & filterName
            if fileExists(fmt"./{repoName}/{filterName}/filter.json"):
                result.add(newFilter(filterName, filterUrl))
        os.removeDir("./" & repoName)
    os.setCurrentDir(root)
    os.removeDir("./tmp")

var app = newApp()
var filters = getFilters()
app.get(
  "/filters",
  proc(ctx: Context) {.async.} = await ctx.text(filters.join("\n").replace("\\\"", ""))
)
waitFor app.run