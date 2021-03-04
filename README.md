# moss_nim
[Moss](https://theory.stanford.edu/~aiken/moss/) (Measure of Software Submission) submission script in Nim.

## Usage
```
import browsers, moss_nim, os

var moss = initMossNim(userid = getEnv("MOSS_USERID"), language = "python")
moss.addBaseFile("submission/test.py")
moss.addFile("submission/test2.py")
moss.addFilesByWildcard("submission/tests*.py")

var url: string = moss.send()
echo("URL: " & url)
openDefaultBrowser(url)
```
## Inspiration
This project is inspired by the [original Bash script](http://moss.stanford.edu/general/scripts/mossnet) implementation and a [Python version](https://github.com/soachishti/moss.py).
