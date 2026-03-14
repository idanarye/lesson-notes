#!/usr/bin/env nu

def main [] {
    let chosen = gen-options | sk -p {} -f {format pattern '{he} {type} {by}'}
    let template = open --raw template.lyx
    let lyx_code = $template | str replace --all --regex '<(\w+)>' {|var|
        let orig = $in
        match $var {
            'he' => $chosen.he
            'code' => ($chosen | format pattern '{code}-{group_code}')
            'by' => $chosen.by
            'date' => $chosen.date
            _ => $orig
        }
    }
    let directory = 'master' | path join ($chosen | format pattern '{code}-{en}')
    mkdir $directory
    let filename = $chosen | format pattern '{code}{type}{date}.lyx'
    let full_path = $directory | path join $filename
    $lyx_code o> $full_path
    # bash -ce 'nohup lyx "@1"' o> /dev/null e> /dev/null $full_path
    bash -ce 'nohup lyx "$1"' -- $full_path o> /dev/null e> /dev/null
}

def gen-options [] {
    open lessons-db.toml | get courses | items {|en, details| 
        let date = date now | format date '%Y-%m-%d'
        def emit-items [type: string, group_code: string] {
            each {|name| {
                code: $details.code
                group_code: $group_code
                en: $en
                type: $type
                he: $details.he
                by: $name
                date: $date
            }}
        }
        [
            ($details.lecturer | each {emit-items l $details.lecture_group})
            ($details.tutor | each {emit-items t $details.tutor_group})
        ] | flatten
    } | flatten
}
