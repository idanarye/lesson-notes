#!/usr/bin/env nu

let all_lessons = ls **/*.lyx | insert lesson_date {
    get name | path basename | parse --regex r#'^[\d-]+[lte](?<date>\d{4}-\d{2}-\d{2})\.lyx$'# | get --optional date.0
} | where lesson_date != null | insert course_dir {
    get name | path dirname
}

let all_courses = $all_lessons | group-by --to-table course_dir | update items {
    let dates = $in | get lesson_date
    {
        min: ($dates | math min)
        max: ($dates | math max)
    }
} | insert from_date {get items.min} | insert to_date {get items.max} | reject items | insert basedir {
    get course_dir | path basename
} | where {|course|
    cd wt.gh-pages
    $course.basedir | path exists 
} | sort-by from_date

let hb = handlebars new

let tpl_main_index = $hb | handlebars compile --file gh-templates/main-index.html.hbs
let tpl_course_index = $hb | handlebars compile --file gh-templates/course-index.html.hbs

touch wt.gh-pages/.nojekyll

$all_courses | handlebars render $tpl_main_index o> wt.gh-pages/index.html

$all_courses | each {|course|
    cd wt.gh-pages
    cd $course.basedir

    let pdfs = ls *.pdf | get name | each {|file|
        let parsed = parse --regex r#'(?<type>[lt])(?<date>\d{4}-\d{2}-\d{2}).pdf'# | get --optional 0
        if $parsed == null {
            return
        }
        {
            file: $file
            title: (match $parsed.type {
                "l" => "Lectures"
                "t" => "Tutors"
            })
            date: $parsed.date
        }
    } | sort-by title date | group-by --to-table --prune title

    $course | insert pdfs $pdfs | handlebars render $tpl_course_index o> index.html
}

null
