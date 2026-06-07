#!/usr/bin/env nu

mkdir wt.gh-pages/.hashes

let all = ls **/*.lyx | where {get name | path basename | $in != "template.lyx"} | each {|notes|
    let parsed = $notes.name | path parse
    let course = $parsed.parent | path basename
    let stem = $parsed.stem
    {
        lyx: $notes.name
        hash: (open --raw $notes.name | hash md5)
        md5: $"wt.gh-pages/.hashes/($stem).md5"
        pdf: $"wt.gh-pages/($course)/($stem).pdf"
    }
}


let to_build = $all | where {|notes|
    let existing = try { open --raw $notes.md5 } catch { return true }
    $existing != $notes.hash
}

let faulty = $to_build | each {|notes|
    try {
        lyx --export-to pdf $notes.pdf $notes.lyx
        $notes.hash o> $notes.md5
    } catch {
        $notes.lyx
    }
}

if ($faulty | is-not-empty) {
    print "Could not build:"
    print $faulty
}

do {
    cd wt.gh-pages/
    git status
}
