#!/usr/bin/env nu

cd wt.gh-pages/

git add --all
git commit -m $"Updating pages (date now)"
git push
