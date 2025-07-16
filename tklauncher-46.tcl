#part--1
#!/usr/bin/env wish

package require Tk

wm withdraw .

set BASE_DIR [pwd]
set BUTTON_DIR [file join $BASE_DIR ".launcher_buttons"]
set ICON_CACHE_DIR [file join $BASE_DIR ".launcher_icon_cache"]
set CONFIG_FILE [file join $BASE_DIR "config.conf"]
set ICON_TYPE_CACHE_FILE [file join $ICON_CACHE_DIR ".icon_type_cache"]
set button_to_desktop [dict create]
set search_terms [dict create]
set ICON_TYPE_CACHE [dict create]
set settings_panel_visible 0
set categories_panel_visible 0
set config [dict create Layout [dict create button_padding 10 icon_scale 1.0 bg_left "#d9d9d9" bg_right "#ffffff" font_color "#000000" cat_font_color "#000000" selection_color "#87CEEB" button_border_color "#808080" search_entry_border_width 0]]

set categories {
    "Рабочий стол" {Desktop Utility FileTools}
    "Все" {Network WebBrowser Email Chat Office WordProcessor Spreadsheet Presentation Utility FileTools Calculator System Settings Administration Audio Video}
}

proc log {message} {
    puts "[clock format [clock seconds] -format %H:%M:%S]: $message"
}

proc load_icon_type_cache {} {
    global ICON_TYPE_CACHE ICON_TYPE_CACHE_FILE
    if {[file exists $ICON_TYPE_CACHE_FILE]} {
        set fd [open $ICON_TYPE_CACHE_FILE r]
        set data [read $fd]
        close $fd
        set ICON_TYPE_CACHE [dict create {*}$data]
    }
}

proc save_icon_type_cache {} {
    global ICON_TYPE_CACHE ICON_TYPE_CACHE_FILE
    set fd [open $ICON_TYPE_CACHE_FILE w]
    puts $fd $ICON_TYPE_CACHE
    close $fd
}

proc load_config {} {
    global CONFIG_FILE config
    if {[file exists $CONFIG_FILE]} {
        set fd [open $CONFIG_FILE r]
        set data [read $fd]
        close $fd
        foreach line [split $data "\n"] {
            set line [string trim $line]
            if {[string match "\[Layout\]" $line]} {continue}
            if {[string match "button_padding=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^[0-9]+$} $value]} {
                    dict set config Layout button_padding $value
                }
            }
            if {[string match "icon_scale=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^[0-9]+\.?[0-9]*$} $value] && $value >= 0.5 && $value <= 3.0} {
                    dict set config Layout icon_scale $value
                }
            }
            if {[string match "bg_left=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^#[0-9a-fA-F]{6}$} $value]} {
                    dict set config Layout bg_left $value
                }
            }
            if {[string match "bg_right=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^#[0-9a-fA-F]{6}$} $value]} {
                    dict set config Layout bg_right $value
                }
            }
            if {[string match "font_color=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^#[0-9a-fA-F]{6}$} $value]} {
                    dict set config Layout font_color $value
                }
            }
            if {[string match "cat_font_color=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^#[0-9a-fA-F]{6}$} $value]} {
                    dict set config Layout cat_font_color $value
                }
            }
            if {[string match "selection_color=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^#[0-9a-fA-F]{6}$} $value]} {
                    dict set config Layout selection_color $value
                }
            }
            if {[string match "button_border_color=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^#[0-9a-fA-F]{6}$} $value]} {
                    dict set config Layout button_border_color $value
                }
            }
            if {[string match "search_entry_border_width=*" $line]} {
                set value [string trim [string range $line [expr {[string first "=" $line] + 1}] end]]
                if {[regexp {^[0-5]$} $value]} {
                    dict set config Layout search_entry_border_width $value
                }
            }
        }
    }
}

proc save_config {} {
    global CONFIG_FILE config
    set fd [open $CONFIG_FILE w]
    puts $fd "\[Layout\]"
    puts $fd "button_padding=[dict get $config Layout button_padding]"
    puts $fd "icon_scale=[dict get $config Layout icon_scale]"
    puts $fd "bg_left=[dict get $config Layout bg_left]"
    puts $fd "bg_right=[dict get $config Layout bg_right]"
    puts $fd "font_color=[dict get $config Layout font_color]"
    puts $fd "cat_font_color=[dict get $config Layout cat_font_color]"
    puts $fd "selection_color=[dict get $config Layout selection_color]"
    puts $fd "button_border_color=[dict get $config Layout button_border_color]"
    puts $fd "search_entry_border_width=[dict get $config Layout search_entry_border_width]"
    close $fd
}

#part--2
proc update_scale {delta} {
    global config main
    set current_scale [dict get $config Layout icon_scale]
    set new_scale [expr {$current_scale + ($delta > 0 ? 0.1 : -0.1)}]
    if {$new_scale >= 0.5 && $new_scale <= 3.0} {
        dict set config Layout icon_scale $new_scale
        apply_scale
        save_config
    }
}

proc apply_scale {} {
    global config main placeholder_icon
    set scale [dict get $config Layout icon_scale]
    set base_size 48
    set new_size [expr {int($base_size * $scale)}]
    if {$new_size < 48} {set new_size 48}
    
    image delete $placeholder_icon
    set placeholder_icon [image create photo -width $new_size -height $new_size]
    set default_icon_path "/usr/share/icons/hicolor/48x48/apps/system-run.png"
    if {[file exists $default_icon_path]} {
        catch {
            set temp_img [image create photo -file $default_icon_path]
            $placeholder_icon copy $temp_img -shrink -to 0 0 $new_size $new_size
            image delete $temp_img
        }
    }
    
    set sel [$main.categories.list curselection]
    if {$sel ne ""} {
        load_applications [$main.categories.list get $sel]
    }
    set font_size [expr {int(9 * $scale)}]
    if {$font_size < 9} {set font_size 9}
    $main.categories.list configure -font "TkDefaultFont $font_size"
}

proc apply_colors {} {
    global config main
    set bg_left [dict get $config Layout bg_left]
    set cat_font_color [dict get $config Layout cat_font_color]
    set selection_color [dict get $config Layout selection_color]
    set button_border_color [dict get $config Layout button_border_color]
    set search_entry_border_width [dict get $config Layout search_entry_border_width]
    
    $main.categories configure -background $bg_left
    $main.categories.list configure -background $bg_left -foreground $cat_font_color -selectbackground $selection_color
    $main.categories.refresh configure -background $bg_left -foreground $cat_font_color
    $main.categories.settings configure -background $bg_left -foreground $cat_font_color
    $main.categories.toggle configure -background $bg_left -foreground $cat_font_color
    
    set bg_right [dict get $config Layout bg_right]
    $main.buttons configure -background $bg_right
    $main.buttons.canvas configure -background $bg_right
    $main.buttons.panel_toggle configure -background $bg_right -foreground $cat_font_color
    $main.search configure -background $bg_right
    $main.search.entry_frame configure -background $selection_color
    $main.search.entry configure -borderwidth $search_entry_border_width
    
    foreach child [$main.buttons.canvas find withtag window] {
        set widget [$main.buttons.canvas itemcget $child -window]
        if {[winfo class $widget] eq "Button"} {
            $widget configure -highlightbackground $button_border_color
        }
    }
    
    set sel [$main.categories.list curselection]
    if {$sel ne ""} {
        load_applications [$main.categories.list get $sel]
    }
}

proc create_directories {} {
    global BUTTON_DIR ICON_CACHE_DIR categories
    if {![file exists $BUTTON_DIR]} {file mkdir $BUTTON_DIR}
    if {![file exists $ICON_CACHE_DIR]} {file mkdir $ICON_CACHE_DIR}
    foreach {cat _} $categories {
        set cat_dir [file join $BUTTON_DIR [string map {" " "_"} $cat]]
        set icon_cat_dir [file join $ICON_CACHE_DIR [string map {" " "_"} $cat]]
        if {![file exists $cat_dir]} {file mkdir $cat_dir}
        if {![file exists $icon_cat_dir]} {file mkdir $icon_cat_dir}
    }
}

proc create_placeholder_icon {} {
    global placeholder_icon config
    set scale [dict get $config Layout icon_scale]
    set base_size 48
    set new_size [expr {int($base_size * $scale)}]
    if {$new_size < 48} {set new_size 48}
    set placeholder_icon [image create photo -width $new_size -height $new_size]
    set default_icon_path "/usr/share/icons/hicolor/48x48/apps/system-run.png"
    if {[file exists $default_icon_path]} {
        catch {
            set temp_img [image create photo -file $default_icon_path]
            $placeholder_icon copy $temp_img -shrink -to 0 0 $new_size $new_size
            image delete $temp_img
        }
    }
}

#part--3
proc parse_desktop_file {file} {
    if {![file exists $file]} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    if {[file type $file] eq "link"} {
        set target [file readlink $file]
        if {[file isdirectory $target]} {
            return {name "" exec "" icon "" categories "" terminal false}
        }
    } elseif {![file isfile $file]} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    set fd [open $file r]
    set data [read $fd]
    close $fd
    set name ""
    set exec_cmd ""
    set icon ""
    set categories ""
    set terminal "false"
    set nodisplay "false"
    set in_desktop_entry 0

    foreach line [split $data "\n"] {
        set line [string trim $line]
        if {$line eq "\[Desktop Entry\]"} {set in_desktop_entry 1; continue}
        if {[string match {\[*\]} $line]} {set in_desktop_entry 0; continue}
        if {!$in_desktop_entry} {continue}
        if {[string match "Name=*" $line]} {set name [string range $line 5 end]}
        if {[string match "Exec=*" $line]} {
            set exec_cmd [string trim [string range $line 5 end]]
            regsub -all {%[A-Za-z]} $exec_cmd "" exec_cmd
        }
        if {[string match "Icon=*" $line]} {set icon [string range $line 5 end]}
        if {[string match "Categories=*" $line]} {set categories [string range $line 11 end]}
        if {[string match "Terminal=*" $line]} {set terminal [string range $line 9 end]}
        if {[string match "NoDisplay=*" $line]} {set nodisplay [string range $line 10 end]}
    }
    if {$nodisplay eq "true"} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    if {$name eq ""} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    if {$exec_cmd eq ""} {
        set exec_cmd "echo 'Команда отсутствует'"
    }
    return [list name $name exec $exec_cmd icon $icon categories $categories terminal $terminal]
}

proc find_icon {icon_name exec_cmd {is_symlink 0}} {
    global ICON_CACHE_DIR placeholder_icon config
    set scale [dict get $config Layout icon_scale]
    set new_size [expr {int(48 * $scale)}]
    if {$new_size < 48} {set new_size 48}

    set base_name [file tail $icon_name]
    set cached_icon [file join $ICON_CACHE_DIR "$base_name.png"]

    set web_apps_icon "/home/live/.local/bin/pwa_similar/icons/web_apps.png"
    set web_apps_cached [file join $ICON_CACHE_DIR "web_apps.png"]

    if {$is_symlink} {
        set symlink_icon_path "/usr/share/icons/Adwaita/48x48/emblems/emblem-symbolic-link.png"
        if {[file exists $symlink_icon_path]} {
            set cached_icon [file join $ICON_CACHE_DIR "emblem-symbolic-link.png"]
            if {![file exists $cached_icon]} {
                catch {
                    exec convert -background none -resize ${new_size}x${new_size}! $symlink_icon_path $cached_icon 2>@ stderr
                }
            }
            if {[file exists $cached_icon]} {
                return [image create photo -file $cached_icon]
            }
        }
    }

    if {[file exists $cached_icon]} {
        return [image create photo -file $cached_icon]
    }

    proc fallback_to_web_apps {icon_path cached_icon web_apps_icon web_apps_cached new_size} {
        if {[file exists $web_apps_icon]} {
            catch {
                exec convert -background none -resize ${new_size}x${new_size}! $web_apps_icon $web_apps_cached 2>@ stderr
                if {[file exists $web_apps_cached]} {
                    return [image create photo -file $web_apps_cached]
                }
            }
        }
        return $::placeholder_icon
    }

    proc process_ico {icon_path cached_icon new_size} {
        global ICON_TYPE_CACHE
        if {[dict exists $ICON_TYPE_CACHE $icon_path]} {
            set file_type [dict get $ICON_TYPE_CACHE $icon_path]
        } else {
            catch {
                set file_type [exec file -b $icon_path]
                dict set ICON_TYPE_CACHE $icon_path $file_type
            } result
            if {![info exists file_type]} {
                return 0
            }
        }
        
        if {[string match "*ICO*" $file_type] || [string match "*icon*" $file_type]} {
            set temp_png "/tmp/temp_icon_[clock milliseconds].png"
            catch {
                exec icotool -x -i 1 $icon_path -o $temp_png 2>@ stderr
                if {[file exists $temp_png]} {
                    exec convert -background none -resize ${new_size}x${new_size}! $temp_png $cached_icon 2>@ stderr
                    file delete $temp_png
                    if {[file exists $cached_icon]} {
                        return 1
                    }
                }
            }
            return 0
        }
        return 0
    }

    if {[file exists $icon_name]} {
        if {[process_ico $icon_name $cached_icon $new_size]} {
            return [image create photo -file $cached_icon]
        }
        catch {
            exec convert -background none -resize ${new_size}x${new_size}! $icon_name $cached_icon 2>@ stderr
            if {[file exists $cached_icon]} {
                return [image create photo -file $cached_icon]
            }
        }
        if {![file exists $cached_icon]} {
            return [fallback_to_web_apps $icon_name $cached_icon $web_apps_icon $web_apps_cached $new_size]
        }
    }

    set pwa_icon_dir "/home/live/.local/bin/pwa_similar/icons"
    set formats { ".png" ".svg" ".xpm" ".jpg" ".jpeg" }
    if {[file exists $pwa_icon_dir]} {
        foreach fmt $formats {
            set pwa_icon_path [file join $pwa_icon_dir "$base_name$fmt"]
            if {[file exists $pwa_icon_path]} {
                if {[process_ico $pwa_icon_path $cached_icon $new_size]} {
                    return [image create photo -file $cached_icon]
                }
                catch {
                    exec convert -background none -resize ${new_size}x${new_size}! $pwa_icon_path $cached_icon 2>@ stderr
                    if {[file exists $cached_icon]} {
                        return [image create photo -file $cached_icon]
                    }
                }
                if {![file exists $cached_icon]} {
                    return [fallback_to_web_apps $pwa_icon_path $cached_icon $web_apps_icon $web_apps_cached $new_size]
                }
            }
        }
    }

    set icon_dirs {
        "/home/live/.icons"
        "/usr/share/icons"
        "/usr/local/share/icons"
        "/usr/share/pixmaps"
    }
    set themes { "hicolor" "Adwaita" "gnome" }
    catch {
        set theme [exec gsettings get org.gnome.desktop.interface icon-theme]
        set theme [string trim $theme "'"]
        if {$theme ne ""} {linsert $themes 0 $theme}
    }
    set sizes { "48x48" "64x64" "128x128" "32x32" "scalable" }

    foreach theme $themes {
        foreach dir $icon_dirs {
            foreach size $sizes {
                foreach fmt $formats {
                    set icon_path "$dir/$theme/$size/apps/$base_name$fmt"
                    if {[file exists $icon_path]} {
                        if {[process_ico $icon_path $cached_icon $new_size]} {
                            return [image create photo -file $cached_icon]
                        }
                        catch {
                            exec convert -background none -resize ${new_size}x${new_size}! $icon_path $cached_icon 2>@ stderr
                            if {[file exists $cached_icon]} {
                                return [image create photo -file $cached_icon]
                            }
                        }
                        if {![file exists $cached_icon]} {
                            return [fallback_to_web_apps $icon_path $cached_icon $web_apps_icon $web_apps_cached $new_size]
                        }
                    }
                }
            }
        }
    }

    return $placeholder_icon
}

#part--3
proc parse_desktop_file {file} {
    if {![file exists $file]} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    if {[file type $file] eq "link"} {
        set target [file readlink $file]
        if {[file isdirectory $target]} {
            return {name "" exec "" icon "" categories "" terminal false}
        }
    } elseif {![file isfile $file]} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    set fd [open $file r]
    set data [read $fd]
    close $fd
    set name ""
    set exec_cmd ""
    set icon ""
    set categories ""
    set terminal "false"
    set nodisplay "false"
    set in_desktop_entry 0

    foreach line [split $data "\n"] {
        set line [string trim $line]
        if {$line eq "\[Desktop Entry\]"} {set in_desktop_entry 1; continue}
        if {[string match {\[*\]} $line]} {set in_desktop_entry 0; continue}
        if {!$in_desktop_entry} {continue}
        if {[string match "Name=*" $line]} {set name [string range $line 5 end]}
        if {[string match "Exec=*" $line]} {
            set exec_cmd [string trim [string range $line 5 end]]
            regsub -all {%[A-Za-z]} $exec_cmd "" exec_cmd
        }
        if {[string match "Icon=*" $line]} {set icon [string range $line 5 end]}
        if {[string match "Categories=*" $line]} {set categories [string range $line 11 end]}
        if {[string match "Terminal=*" $line]} {set terminal [string range $line 9 end]}
        if {[string match "NoDisplay=*" $line]} {set nodisplay [string range $line 10 end]}
    }
    if {$nodisplay eq "true"} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    if {$name eq ""} {
        return {name "" exec "" icon "" categories "" terminal false}
    }
    if {$exec_cmd eq ""} {
        set exec_cmd "echo 'Команда отсутствует'"
    }
    return [list name $name exec $exec_cmd icon $icon categories $categories terminal $terminal]
}

proc find_icon {icon_name exec_cmd {is_symlink 0}} {
    global ICON_CACHE_DIR placeholder_icon config
    set scale [dict get $config Layout icon_scale]
    set new_size [expr {int(48 * $scale)}]
    if {$new_size < 48} {set new_size 48}

    set base_name [file tail $icon_name]
    set cached_icon [file join $ICON_CACHE_DIR "$base_name.png"]

    set web_apps_icon "/home/live/.local/bin/pwa_similar/icons/web_apps.png"
    set web_apps_cached [file join $ICON_CACHE_DIR "web_apps.png"]

    if {$is_symlink} {
        set symlink_icon_path "/usr/share/icons/Adwaita/48x48/emblems/emblem-symbolic-link.png"
        if {[file exists $symlink_icon_path]} {
            set cached_icon [file join $ICON_CACHE_DIR "emblem-symbolic-link.png"]
            if {![file exists $cached_icon]} {
                catch {
                    exec convert -background none -resize ${new_size}x${new_size}! $symlink_icon_path $cached_icon 2>@ stderr
                }
            }
            if {[file exists $cached_icon]} {
                return [image create photo -file $cached_icon]
            }
        }
    }

    if {[file exists $cached_icon]} {
        return [image create photo -file $cached_icon]
    }

    proc fallback_to_web_apps {icon_path cached_icon web_apps_icon web_apps_cached new_size} {
        if {[file exists $web_apps_icon]} {
            catch {
                exec convert -background none -resize ${new_size}x${new_size}! $web_apps_icon $web_apps_cached 2>@ stderr
                if {[file exists $web_apps_cached]} {
                    return [image create photo -file $web_apps_cached]
                }
            }
        }
        return $::placeholder_icon
    }

    proc process_ico {icon_path cached_icon new_size} {
        global ICON_TYPE_CACHE
        if {[dict exists $ICON_TYPE_CACHE $icon_path]} {
            set file_type [dict get $ICON_TYPE_CACHE $icon_path]
        } else {
            catch {
                set file_type [exec file -b $icon_path]
                dict set ICON_TYPE_CACHE $icon_path $file_type
            } result
            if {![info exists file_type]} {
                return 0
            }
        }
        
        if {[string match "*ICO*" $file_type] || [string match "*icon*" $file_type]} {
            set temp_png "/tmp/temp_icon_[clock milliseconds].png"
            catch {
                exec icotool -x -i 1 $icon_path -o $temp_png 2>@ stderr
                if {[file exists $temp_png]} {
                    exec convert -background none -resize ${new_size}x${new_size}! $temp_png $cached_icon 2>@ stderr
                    file delete $temp_png
                    if {[file exists $cached_icon]} {
                        return 1
                    }
                }
            }
            return 0
        }
        return 0
    }

    if {[file exists $icon_name]} {
        if {[process_ico $icon_name $cached_icon $new_size]} {
            return [image create photo -file $cached_icon]
        }
        catch {
            exec convert -background none -resize ${new_size}x${new_size}! $icon_name $cached_icon 2>@ stderr
            if {[file exists $cached_icon]} {
                return [image create photo -file $cached_icon]
            }
        }
        if {![file exists $cached_icon]} {
            return [fallback_to_web_apps $icon_name $cached_icon $web_apps_icon $web_apps_cached $new_size]
        }
    }

    set pwa_icon_dir "/home/live/.local/bin/pwa_similar/icons"
    set formats { ".png" ".svg" ".xpm" ".jpg" ".jpeg" }
    if {[file exists $pwa_icon_dir]} {
        foreach fmt $formats {
            set pwa_icon_path [file join $pwa_icon_dir "$base_name$fmt"]
            if {[file exists $pwa_icon_path]} {
                if {[process_ico $pwa_icon_path $cached_icon $new_size]} {
                    return [image create photo -file $cached_icon]
                }
                catch {
                    exec convert -background none -resize ${new_size}x${new_size}! $pwa_icon_path $cached_icon 2>@ stderr
                    if {[file exists $cached_icon]} {
                        return [image create photo -file $cached_icon]
                    }
                }
                if {![file exists $cached_icon]} {
                    return [fallback_to_web_apps $pwa_icon_path $cached_icon $web_apps_icon $web_apps_cached $new_size]
                }
            }
        }
    }

    set icon_dirs {
        "/home/live/.icons"
        "/usr/share/icons"
        "/usr/local/share/icons"
        "/usr/share/pixmaps"
    }
    set themes { "hicolor" "Adwaita" "gnome" }
    catch {
        set theme [exec gsettings get org.gnome.desktop.interface icon-theme]
        set theme [string trim $theme "'"]
        if {$theme ne ""} {linsert $themes 0 $theme}
    }
    set sizes { "48x48" "64x64" "128x128" "32x32" "scalable" }

    foreach theme $themes {
        foreach dir $icon_dirs {
            foreach size $sizes {
                foreach fmt $formats {
                    set icon_path "$dir/$theme/$size/apps/$base_name$fmt"
                    if {[file exists $icon_path]} {
                        if {[process_ico $icon_path $cached_icon $new_size]} {
                            return [image create photo -file $cached_icon]
                        }
                        catch {
                            exec convert -background none -resize ${new_size}x${new_size}! $icon_path $cached_icon 2>@ stderr
                            if {[file exists $cached_icon]} {
                                return [image create photo -file $cached_icon]
                            }
                        }
                        if {![file exists $cached_icon]} {
                            return [fallback_to_web_apps $icon_path $cached_icon $web_apps_icon $web_apps_cached $new_size]
                        }
                    }
                }
            }
        }
    }

    return $placeholder_icon
}

#part--4
proc change_icon {button name exec_cmd desktop_file} {
    global ICON_CACHE_DIR main config
    set scale [dict get $config Layout icon_scale]
    set new_size [expr {int(48 * $scale)}]
    if {$new_size < 48} {set new_size 48}

    set file_types {
        {{Image Files} {.png .jpg .jpeg .svg .xpm .ico}}
        {{All Files} *}
    }
    
    set new_icon_path [tk_getOpenFile -filetypes $file_types -title "Выберите новую иконку" -parent $main]
    if {$new_icon_path eq ""} {return}

    set cat [lindex [split [file dirname $desktop_file] "/"] end]
    set icon_cat_dir [file join $ICON_CACHE_DIR [string map {" " "_"} $cat]]
    set cache_file [file join $icon_cat_dir "[string map {/ _} $name].png"]
    
    if {[file exists $cache_file]} {file delete $cache_file}
    catch {
        if {[string match "*.ico" $new_icon_path]} {
            set temp_png "/tmp/temp_icon_[clock milliseconds].png"
            exec icotool -x -i 1 $new_icon_path -o $temp_png 2>@ stderr
            if {[file exists $temp_png]} {
                exec convert -background none -resize ${new_size}x${new_size}! $temp_png $cache_file 2>@ stderr
                file delete $temp_png
            }
        } else {
            exec convert -background none -resize ${new_size}x${new_size}! $new_icon_path $cache_file 2>@ stderr
        }
        if {[file exists $cache_file]} {
            set new_img [image create photo -file $cache_file]
            $button configure -image $new_img
            update idletasks
        }
    }
}

proc delete_button {button name desktop_file canvas} {
    global ICON_CACHE_DIR button_to_desktop main search_terms
    
    if {[file exists $desktop_file]} {file delete $desktop_file}
    set cat [lindex [split [file dirname $desktop_file] "/"] end]
    set icon_cat_dir [file join $ICON_CACHE_DIR [string map {" " "_"} $cat]]
    set cache_file [file join $icon_cat_dir "[string map {/ _} $name].png"]
    if {[file exists $cache_file]} {file delete $cache_file}
    
    dict unset button_to_desktop $name
    dict unset search_terms $name
    destroy $button
    destroy $canvas.lbl_[string map {. _ : _ / _ " " _} $name]
    
    set sel [$main.categories.list curselection]
    if {$sel ne ""} {
        load_applications [$main.categories.list get $sel]
    }
}

proc copy_to_desktop {button name exec_cmd desktop_file canvas} {
    global BUTTON_DIR ICON_CACHE_DIR button_to_desktop placeholder_icon main
    
    set desktop_cat_dir [file join $BUTTON_DIR "Рабочий_стол"]
    set icon_cat_dir [file join $ICON_CACHE_DIR "Рабочий_стол"]
    set desktop_filename [file tail $desktop_file]
    set dest_file [file join $desktop_cat_dir $desktop_filename]
    
    if {![file exists $dest_file]} {
        file copy -force $desktop_file $dest_file
        set info [parse_desktop_file $desktop_file]
        set icon [dict get $info icon]
        dict set button_to_desktop $name $dest_file
        
        if {$icon ne ""} {
            set img [find_icon $icon $exec_cmd]
            if {$img ne $placeholder_icon} {
                set cache_file [file join $icon_cat_dir "[string map {/ _} $name].png"]
                catch {$img write $cache_file -format png}
            }
        }
        
        set sel [$main.categories.list curselection]
        if {$sel ne "" && [$main.categories.list get $sel] eq "Рабочий стол"} {
            load_applications "Рабочий стол"
        }
    }
}

proc handle_button_press {button exec_cmd name desktop_file} {
    global press_time long_press_id
    set press_time [clock milliseconds]
    set long_press_id [after 500 [list handle_long_press $button $name $exec_cmd $desktop_file]]
}

proc handle_long_press {button name exec_cmd desktop_file} {
    global press_time long_press_id
    if {[info exists long_press_id]} {
        change_icon $button $name $exec_cmd $desktop_file
        unset long_press_id
    }
}

proc handle_button_release {button exec_cmd desktop_file} {
    global press_time long_press_id
    if {[info exists long_press_id]} {
        after cancel $long_press_id
        unset long_press_id
        set release_time [clock milliseconds]
        set duration [expr {$release_time - $press_time}]
        if {$duration < 500} {
            set info [parse_desktop_file $desktop_file]
            set terminal [dict get $info terminal]
            if {$terminal eq "true"} {
                set term_list {xterm uxterm lxterminal xfce4-terminal gnome-terminal terminator konsole}
                set term_cmd ""
                foreach term $term_list {
                    if {[auto_execok $term] ne ""} {
                        set term_cmd $term
                        break
                    }
                }
                if {$term_cmd eq ""} {
                    tk_messageBox -icon error -title "Ошибка" -message "Не найден терминал для запуска приложения!"
                    return
                }
                catch {
                    switch $term_cmd {
                        "xterm" {exec $term_cmd -e sh -c "$exec_cmd ; exec bash" &}
                        "uxterm" {exec $term_cmd -e sh -c "$exec_cmd ; exec bash" &}
                        "lxterminal" {exec $term_cmd -e sh -c "$exec_cmd ; read -p 'Нажмите Enter для закрытия...'" &}
                        "xfce4-terminal" {exec $term_cmd -e "$exec_cmd ; read -p 'Нажмите Enter для закрытия...'" &}
                        "gnome-terminal" {exec $term_cmd -- sh -c "$exec_cmd ; read -p 'Нажмите Enter для закрытия...'" &}
                        "terminator" {exec $term_cmd -e "sh -c '$exec_cmd ; read -p \"Нажмите Enter для закрытия...\"'" &}
                        "konsole" {exec $term_cmd -e sh -c "$exec_cmd ; read -p 'Нажмите Enter для закрытия...'" &}
                        default {exec $term_cmd -e sh -c "$exec_cmd ; exec bash" &}
                    }
                }
            } else {
                catch {exec {*}$exec_cmd &}
            }
        }
    }
}

#part--5
proc collect_desktop_items {dir} {
    set items {}
    set desktop_files [glob -nocomplain -directory $dir "*.desktop"]
    foreach file $desktop_files {
        if {[file isfile $file]} {lappend items $file}
    }
    set symlinks [glob -nocomplain -directory $dir -types {l} *]
    foreach symlink $symlinks {
        if {[file type $symlink] eq "link"} {lappend items $symlink}
    }
    set subdirs [glob -nocomplain -directory $dir -types d *]
    foreach subdir $subdirs {
        if {[file isdirectory $subdir]} {lappend items {*}[collect_desktop_items $subdir]}
    }
    return $items
}

proc build_cache {} {
    global BUTTON_DIR ICON_CACHE_DIR categories button_to_desktop placeholder_icon config
    
    set progress [toplevel .progress]
    wm title $progress "Инициализация кэша"
    wm attributes $progress -topmost 1
    set screen_width [winfo screenwidth .]
    set screen_height [winfo screenheight .]
    set win_width 400
    set win_height 100
    set x [expr {($screen_width - $win_width) / 2}]
    set y [expr {($screen_height - $win_height) / 2}]
    wm geometry $progress ${win_width}x${win_height}+${x}+${y}
    
    set bg_color [dict get $config Layout bg_right]
    set fg_color [dict get $config Layout font_color]
    
    $progress configure -background $bg_color
    
    frame $progress.content -background $bg_color -borderwidth 1 -relief groove
    pack $progress.content -expand true -fill both -padx 10 -pady 10
    
    label $progress.content.label -text "Формирование кэша, пожалуйста, подождите..." \
        -background $bg_color -foreground $fg_color -font "TkDefaultFont 9"
    pack $progress.content.label -pady 5
    
    ttk::progressbar $progress.content.bar -mode determinate -maximum 100 -value 0
    pack $progress.content.bar -fill x -pady 5
    
    update idletasks

    set desktop_cat_dir [file join $BUTTON_DIR "Рабочий_стол"]
    set desktop_icon_dir [file join $ICON_CACHE_DIR "Рабочий_стол"]
    set all_cat_dir [file join $BUTTON_DIR "Все"]
    set all_icon_dir [file join $ICON_CACHE_DIR "Все"]
    set existing_desktop_files {}
    set existing_icon_files {}
    if {[file exists $desktop_cat_dir]} {
        set existing_desktop_files [glob -nocomplain -directory $desktop_cat_dir "*.desktop"]
    }
    if {[file exists $desktop_icon_dir]} {
        set existing_icon_files [glob -nocomplain -directory $desktop_icon_dir "*.png"]
    }

    set desktop_dir "/home/live/Рабочий стол"
    set desktop_dir_alt "/home/live/Desktop"
    set other_dirs {
        "/home/live/.local/share/applications"
        "/usr/share/applications"
        "/usr/local/share/applications"
    }

    set selected_desktop_dir ""
    if {[file exists $desktop_dir]} {
        set selected_desktop_dir $desktop_dir
    } elseif {[file exists $desktop_dir_alt]} {
        set selected_desktop_dir $desktop_dir_alt
    }

    set total_items 0
    set processed_items 0
    if {[llength $existing_desktop_files] == 0 && $selected_desktop_dir ne ""} {
        set desktop_items [collect_desktop_items $selected_desktop_dir]
        set total_items [llength $desktop_items]
    }
    set other_files {}
    foreach dir $other_dirs {
        if {[file exists $dir]} {
            set files [glob -nocomplain -directory $dir "*.desktop"]
            lappend other_files {*}$files
        }
    }
    set total_items [expr {$total_items + [llength $other_files]}]
    if {$total_items == 0} {
        destroy $progress
        return
    }

    if {[llength $existing_desktop_files] == 0 && $selected_desktop_dir ne ""} {
        set desktop_items [collect_desktop_items $selected_desktop_dir]
        foreach item $desktop_items {
            set cat_dir [file join $BUTTON_DIR "Рабочий_стол"]
            set icon_cat_dir [file join $ICON_CACHE_DIR "Рабочий_стол"]
            set item_filename [file tail $item]
            set dest_file [file join $cat_dir "$item_filename.desktop"]

            if {[file type $item] eq "link"} {
                set target [file readlink $item]
                set name [file rootname [file tail $item]]
                set exec_cmd "xdg-open $target"
                set icon "emblem-symbolic-link"
                set fd [open $dest_file w]
                puts $fd "\[Desktop Entry\]"
                puts $fd "Name=$name (Ссылка)"
                puts $fd "Exec=$exec_cmd"
                puts $fd "Type=Application"
                puts $fd "Icon=$icon"
                close $fd
            } else {
                file copy -force $item $dest_file
            }

            set info [parse_desktop_file $dest_file]
            set name [dict get $info name]
            set exec_cmd [dict get $info exec]
            set icon [dict get $info icon]
            if {$name ne "" && $exec_cmd ne ""} {
                dict set button_to_desktop $name $dest_file
                if {$icon ne ""} {
                    set is_symlink [string match "* (Ссылка)" $name]
                    set img [find_icon $icon $exec_cmd $is_symlink]
                    if {$img ne $placeholder_icon} {
                        set cache_file [file join $icon_cat_dir "[string map {/ _} $name].png"]
                        catch {$img write $cache_file -format png}
                    }
                }
            }
            incr processed_items
            $progress.content.bar configure -value [expr {($processed_items * 100) / $total_items}]
            update idletasks
        }
    }

    foreach file $other_files {
        set info [parse_desktop_file $file]
        set name [dict get $info name]
        set exec_cmd [dict get $info exec]
        set icon [dict get $info icon]
        set file_cats [split [dict get $info categories] ";"]
        if {$name eq "" || $exec_cmd eq ""} {continue}

        set cat "Все"
        set cat_dir [file join $BUTTON_DIR [string map {" " "_"} $cat]]
        set icon_cat_dir [file join $ICON_CACHE_DIR [string map {" " "_"} $cat]]
        set desktop_filename [file tail $file]
        set dest_file [file join $cat_dir $desktop_filename]
        file copy -force $file $dest_file
        dict set button_to_desktop $name $dest_file

        if {$icon ne ""} {
            set img [find_icon $icon $exec_cmd]
            if {$img ne $placeholder_icon} {
                set cache_file [file join $icon_cat_dir "[string map {/ _} $name].png"]
                catch {$img write $cache_file -format png}
            }
        }

        incr processed_items
        $progress.content.bar configure -value [expr {($processed_items * 100) / $total_items}]
        update idletasks
    }

    destroy $progress
}

proc check_for_new_desktop_files {} {
    global main BUTTON_DIR ICON_CACHE_DIR
    
    set desktop_cat_dir [file join $BUTTON_DIR "Рабочий_стол"]
    set desktop_icon_dir [file join $ICON_CACHE_DIR "Рабочий_стол"]
    set tmp_dir [file join [pwd] "tmp" "desc"]
    set tmp_icon_dir [file join [pwd] "tmp" "icon_cache"]
    
    if {![file exists $tmp_dir]} {file mkdir $tmp_dir}
    if {![file exists $tmp_icon_dir]} {file mkdir $tmp_icon_dir}
    
    if {[file exists $desktop_cat_dir]} {
        set desktop_files [glob -nocomplain -directory $desktop_cat_dir "*.desktop"]
        foreach file $desktop_files {
            set dest_file [file join $tmp_dir [file tail $file]]
            file copy -force $file $dest_file
        }
    }
    if {[file exists $desktop_icon_dir]} {
        set icon_files [glob -nocomplain -directory $desktop_icon_dir "*.png"]
        foreach file $icon_files {
            set dest_file [file join $tmp_icon_dir [file tail $file]]
            file copy -force $file $dest_file
        }
    }
    
    build_cache
    
    if {[file exists $tmp_dir]} {
        set tmp_files [glob -nocomplain -directory $tmp_dir "*.desktop"]
        foreach file $tmp_files {
            set dest_file [file join $desktop_cat_dir [file tail $file]]
            file copy -force $file $dest_file
        }
        file delete -force $tmp_dir
    }
    if {[file exists $tmp_icon_dir]} {
        set tmp_icon_files [glob -nocomplain -directory $tmp_icon_dir "*.png"]
        foreach file $tmp_icon_files {
            set dest_file [file join $desktop_icon_dir [file tail $file]]
            file copy -force $file $dest_file
        }
        file delete -force $tmp_icon_dir
    }
    
    set sel [$main.categories.list curselection]
    if {$sel ne ""} {
        set category [$main.categories.list get $sel]
    } else {
        set category "Рабочий стол"
        $main.categories.list selection set 0
        $main.categories.list activate 0
    }
    load_applications $category
}

proc initialize_cache {} {
    global BUTTON_DIR categories
    set cache_empty 1
    foreach {cat _} $categories {
        set cat_dir [file join $BUTTON_DIR [string map {" " "_"} $cat]]
        if {[glob -nocomplain -directory $cat_dir "*.desktop"] ne ""} {
            set cache_empty 0
            break
        }
    }
    if {$cache_empty} {
        build_cache
    }
}

proc open_settings {} {
    global config
    if {[winfo exists .settings]} {destroy .settings}
    set settings [toplevel .settings]
    wm title $settings "Настройки"

    frame $settings.bg_left_frame
    label $settings.bg_left_frame.label -text "Цвет фона левой области:"
    entry $settings.bg_left_frame.entry -width 7 -textvariable ::bg_left_temp
    set ::bg_left_temp [dict get $config Layout bg_left]
    button $settings.bg_left_frame.choose -text "Выбрать" -command {
        set color [tk_chooseColor -initialcolor $::bg_left_temp -title "Выберите цвет фона левой области"]
        if {$color ne ""} {
            set ::bg_left_temp $color
            dict set ::config Layout bg_left $color
            apply_colors
            save_config
        }
    }
    pack $settings.bg_left_frame.label -side left -padx 5 -pady 5
    pack $settings.bg_left_frame.entry -side left -padx 5 -pady 5
    pack $settings.bg_left_frame.choose -side left -padx 5 -pady 5
    pack $settings.bg_left_frame -fill x -padx 10 -pady 5

    frame $settings.bg_right_frame
    label $settings.bg_right_frame.label -text "Цвет фона правой области:"
    entry $settings.bg_right_frame.entry -width 7 -textvariable ::bg_right_temp
    set ::bg_right_temp [dict get $config Layout bg_right]
    button $settings.bg_right_frame.choose -text "Выбрать" -command {
        set color [tk_chooseColor -initialcolor $::bg_right_temp -title "Выберите цвет фона правой области"]
        if {$color ne ""} {
            set ::bg_right_temp $color
            dict set ::config Layout bg_right $color
            apply_colors
            save_config
        }
    }
    pack $settings.bg_right_frame.label -side left -padx 5 -pady 5
    pack $settings.bg_right_frame.entry -side left -padx 5 -pady 5
    pack $settings.bg_right_frame.choose -side left -padx 5 -pady 5
    pack $settings.bg_right_frame -fill x -padx 10 -pady 5

    frame $settings.font_color_frame
    label $settings.font_color_frame.label -text "Цвет шрифта подписей:"
    entry $settings.font_color_frame.entry -width 7 -textvariable ::font_color_temp
    set ::font_color_temp [dict get $config Layout font_color]
    button $settings.font_color_frame.choose -text "Выбрать" -command {
        set color [tk_chooseColor -initialcolor $::font_color_temp -title "Выберите цвет шрифта подписей"]
        if {$color ne ""} {
            set ::font_color_temp $color
            dict set ::config Layout font_color $color
            apply_colors
            save_config
        }
    }
    pack $settings.font_color_frame.label -side left -padx 5 -pady 5
    pack $settings.font_color_frame.entry -side left -padx 5 -pady 5
    pack $settings.font_color_frame.choose -side left -padx 5 -pady 5
    pack $settings.font_color_frame -fill x -padx 10 -pady 5

    frame $settings.cat_font_color_frame
    label $settings.cat_font_color_frame.label -text "Цвет шрифта категорий:"
    entry $settings.cat_font_color_frame.entry -width 7 -textvariable ::cat_font_color_temp
    set ::cat_font_color_temp [dict get $config Layout cat_font_color]
    button $settings.cat_font_color_frame.choose -text "Выбрать" -command {
        set color [tk_chooseColor -initialcolor $::cat_font_color_temp -title "Выберите цвет шрифта категорий"]
        if {$color ne ""} {
            set ::cat_font_color_temp $color
            dict set ::config Layout cat_font_color $color
            apply_colors
            save_config
        }
    }
    pack $settings.cat_font_color_frame.label -side left -padx 5 -pady 5
    pack $settings.cat_font_color_frame.entry -side left -padx 5 -pady 5
    pack $settings.cat_font_color_frame.choose -side left -padx 5 -pady 5
    pack $settings.cat_font_color_frame -fill x -padx 10 -pady 5

    frame $settings.selection_color_frame
    label $settings.selection_color_frame.label -text "Цвет выделения категорий:"
    entry $settings.selection_color_frame.entry -width 7 -textvariable ::selection_color_temp
    set ::selection_color_temp [dict get $config Layout selection_color]
    button $settings.selection_color_frame.choose -text "Выбрать" -command {
        set color [tk_chooseColor -initialcolor $::selection_color_temp -title "Выберите цвет выделения категорий"]
        if {$color ne ""} {
            set ::selection_color_temp $color
            dict set ::config Layout selection_color $color
            apply_colors
            save_config
        }
    }
    pack $settings.selection_color_frame.label -side left -padx 5 -pady 5
    pack $settings.selection_color_frame.entry -side left -padx 5 -pady 5
    pack $settings.selection_color_frame.choose -side left -padx 5 -pady 5
    pack $settings.selection_color_frame -fill x -padx 10 -pady 5

    frame $settings.button_border_color_frame
    label $settings.button_border_color_frame.label -text "Цвет рамки кнопок:"
    entry $settings.button_border_color_frame.entry -width 7 -textvariable ::button_border_color_temp
    set ::button_border_color_temp [dict get $config Layout button_border_color]
    button $settings.button_border_color_frame.choose -text "Выбрать" -command {
        set color [tk_chooseColor -initialcolor $::button_border_color_temp -title "Выберите цвет рамки кнопок"]
        if {$color ne ""} {
            set ::button_border_color_temp $color
            dict set ::config Layout button_border_color $color
            apply_colors
            save_config
        }
    }
    pack $settings.button_border_color_frame.label -side left -padx 5 -pady 5
    pack $settings.button_border_color_frame.entry -side left -padx 5 -pady 5
    pack $settings.button_border_color_frame.choose -side left -padx 5 -pady 5
    pack $settings.button_border_color_frame -fill x -padx 10 -pady 5

    frame $settings.search_entry_border_width_frame
    label $settings.search_entry_border_width_frame.label -text "Толщина внутренней рамки строки поиска (0-5):"
    entry $settings.search_entry_border_width_frame.entry -width 3 -textvariable ::search_entry_border_width_temp
    set ::search_entry_border_width_temp [dict get $config Layout search_entry_border_width]
    button $settings.search_entry_border_width_frame.apply -text "Применить" -command {
        if {[regexp {^[0-5]$} $::search_entry_border_width_temp]} {
            dict set ::config Layout search_entry_border_width $::search_entry_border_width_temp
            apply_colors
            save_config
        } else {
            tk_messageBox -icon warning -title "Ошибка" -message "Введите значение от 0 до 5!"
        }
    }
    pack $settings.search_entry_border_width_frame.label -side left -padx 5 -pady 5
    pack $settings.search_entry_border_width_frame.entry -side left -padx 5 -pady 5
    pack $settings.search_entry_border_width_frame.apply -side left -padx 5 -pady 5
    pack $settings.search_entry_border_width_frame -fill x -padx 10 -pady 5

    frame $settings.button_padding_frame
    label $settings.button_padding_frame.label -text "Отступ между кнопками (0-100):"
    entry $settings.button_padding_frame.entry -width 3 -textvariable ::button_padding_temp
    set ::button_padding_temp [dict get $config Layout button_padding]
    button $settings.button_padding_frame.apply -text "Применить" -command {
        if {[regexp {^[0-9]+$} $::button_padding_temp] && $::button_padding_temp >= 0 && $::button_padding_temp <= 100} {
            dict set ::config Layout button_padding $::button_padding_temp
            save_config
            set sel [$::main.categories.list curselection]
            if {$sel ne ""} {
                set category [$::main.categories.list get $sel]
                $::main.buttons.canvas configure -width 0
                update idletasks
                load_applications $category
            } else {
                $::main.categories.list selection set 0
                $::main.categories.list activate 0
                $::main.buttons.canvas configure -width 0
                update idletasks
                load_applications "Рабочий стол"
            }
        } else {
            tk_messageBox -icon warning -title "Ошибка" -message "Введите значение от 0 до 100!"
        }
    }
    pack $settings.button_padding_frame.label -side left -padx 5 -pady 5
    pack $settings.button_padding_frame.entry -side left -padx 5 -pady 5
    pack $settings.button_padding_frame.apply -side left -padx 5 -pady 5
    pack $settings.button_padding_frame -fill x -padx 10 -pady 5

    button $settings.close -text "Закрыть" -command {destroy .settings}
    pack $settings.close -pady 10
}

#part--6
proc add_app_button {name exec_cmd icon desktop_file canvas x y} {
    global placeholder_icon config search_terms
    set scale [dict get $config Layout icon_scale]
    set new_size [expr {int(48 * $scale)}]
    if {$new_size < 48} {set new_size 48}
    set font_size [expr {int(9 * $scale)}]
    if {$font_size < 9} {set font_size 9}
    
    set safe_name [string map {. _ : _ / _ " " _} $name]
    if {[winfo exists $canvas.btn_$safe_name]} {
        destroy $canvas.btn_$safe_name
        destroy $canvas.lbl_$safe_name
    }
    
    set btn [button $canvas.btn_$safe_name -image $placeholder_icon -borderwidth 0 -width $new_size -height $new_size -background [dict get $config Layout bg_right] -highlightbackground [dict get $config Layout button_border_color]]
    set btn_id [$canvas create window $x $y -window $btn -anchor center]
    
    set lbl [label $canvas.lbl_$safe_name -text $name -font "TkDefaultFont $font_size" -wraplength [expr {$new_size + 20}] -justify center -foreground [dict get $config Layout font_color] -background [dict get $config Layout bg_right]]
    set lbl_id [$canvas create window $x [expr {$y + $new_size/2 + 2}] -window $lbl -anchor n]
    
    bind $btn <Enter> [list show_tooltip %W $name %X %Y]
    bind $btn <Leave> {destroy .tooltip}
    bind $btn <ButtonPress-1> [list handle_button_press %W $exec_cmd $name $desktop_file]
    bind $btn <ButtonRelease-1> [list handle_button_release %W $exec_cmd $desktop_file]
    bind $btn <Button-3> [list delete_button %W $name $desktop_file $canvas]
    bind $btn <Button-2> [list copy_to_desktop %W $name $exec_cmd $desktop_file $canvas]
    
    dict set search_terms $name [list $btn_id $lbl_id $exec_cmd $icon $desktop_file]
    
    return $btn
}

proc load_icon_async {btn icon exec_cmd name desktop_file} {
    global ICON_CACHE_DIR placeholder_icon
    set cat [lindex [split [file dirname $desktop_file] "/"] end]
    set icon_cat_dir [file join $ICON_CACHE_DIR [string map {" " "_"} $cat]]
    set cache_file [file join $icon_cat_dir "[string map {/ _} $name].png"]
    
    if {[file exists $cache_file]} {
        catch {
            set img [image create photo -file $cache_file]
            $btn configure -image $img
        }
    } elseif {$icon ne ""} {
        set is_symlink [string match "* (Ссылка)" $name]
        set img [find_icon $icon $exec_cmd $is_symlink]
        if {$img ne $placeholder_icon} {
            $btn configure -image $img
            catch {$img write $cache_file -format png}
        }
    }
}

proc show_tooltip {widget text x y} {
    if {[winfo exists .tooltip]} {destroy .tooltip}
    set tooltip [toplevel .tooltip -background lightyellow -borderwidth 1 -relief solid]
    wm overrideredirect $tooltip 1
    label $tooltip.label -text $text -background lightyellow -font {TkDefaultFont 9}
    pack $tooltip.label -padx 2 -pady 2
    wm geometry $tooltip +[expr {$x + 10}]+[expr {$y + 10}]
}

proc load_applications {category} {
    global BUTTON_DIR main config button_to_desktop search_terms
    if {![info exists main]} {return}
    
    $main.buttons.canvas delete all
    set search_terms [dict create]
    set button_to_desktop [dict create]
    
    set padding [dict get $config Layout button_padding]
    set scale [dict get $config Layout icon_scale]
    set btn_width [expr {int(48 * $scale)}]
    if {$btn_width < 48} {set btn_width 48}
    set btn_height [expr {int(48 * $scale)}]
    if {$btn_height < 48} {set btn_height 48}
    set cat_dir [file join $BUTTON_DIR [string map {" " "_"} $category]]
    
    if {![file exists $cat_dir]} {return}
    
    set desktop_files [glob -nocomplain -directory $cat_dir "*.desktop"]
    set total_files [llength $desktop_files]
    if {$total_files == 0} {return}
    
    set valid_buttons {}
    foreach desktop_file $desktop_files {
        set info [parse_desktop_file $desktop_file]
        set app_name [dict get $info name]
        set exec_cmd [dict get $info exec]
        set icon [dict get $info icon]
        
        if {$app_name eq "" || $exec_cmd eq ""} {continue}
        lappend valid_buttons [list $app_name $exec_cmd $icon $desktop_file]
    }
    
    set total_buttons [llength $valid_buttons]
    if {$total_buttons == 0} {return}
    
    update idletasks
    set win_width [winfo width $main.buttons.canvas]
    if {$win_width <= 1} {set win_width [expr {[winfo screenwidth .main] - 100}]}
    
    set max_cols [expr {max(1, ($win_width - 2*$padding) / ($btn_width + $padding))}]
    set rows [expr {($total_buttons + $max_cols - 1) / $max_cols}]
    
    set canvas_width $win_width
    set canvas_height [expr {$rows * ($btn_height + 20 + $padding) + $padding}]
    $main.buttons.canvas configure -scrollregion "0 0 $canvas_width $canvas_height"
    $main.buttons.canvas configure -width $canvas_width
    
    set i 0
    foreach btn_info $valid_buttons {
        lassign $btn_info app_name exec_cmd icon desktop_file
        set row [expr {$i / $max_cols}]
        set col [expr {$i % $max_cols}]
        
        if {$row == $rows - 1 && [expr {$total_buttons % $max_cols}] != 0} {
            set cols [expr {$total_buttons % $max_cols}]
        } else {
            set cols $max_cols
        }
        
        set grid_width [expr {$cols * ($btn_width + $padding) - $padding}]
        set start_x [expr {($win_width - $grid_width) / 2}]
        if {$start_x < $padding} {set start_x $padding}
        
        set x [expr {$start_x + $col * ($btn_width + $padding) + $btn_width/2}]
        set y [expr {$row * ($btn_height + 20 + $padding) + $padding + $btn_height/2}]
        
        if {[dict exists $button_to_desktop $app_name]} {
            set unique_name "$app_name ($i)"
        } else {
            set unique_name $app_name
        }
        
        set btn [add_app_button $unique_name $exec_cmd $icon $desktop_file $main.buttons.canvas $x $y]
        dict set button_to_desktop $unique_name $desktop_file
        after 0 [list load_icon_async $btn $icon $exec_cmd $unique_name $desktop_file]
        incr i
    }
}

proc fuzzy_search {query category} {
    global BUTTON_DIR main search_terms config
    if {![info exists main]} {return}
    
    $main.buttons.canvas delete all
    set search_terms [dict create]
    
    if {$query eq ""} {
        load_applications $category
        return
    }
    
    set padding [dict get $config Layout button_padding]
    set scale [dict get $config Layout icon_scale]
    set btn_width [expr {int(48 * $scale)}]
    if {$btn_width < 48} {set btn_width 48}
    set btn_height [expr {int(48 * $scale)}]
    if {$btn_height < 48} {set btn_height 48}
    set cat_dir [file join $BUTTON_DIR [string map {" " "_"} $category]]
    
    if {![file exists $cat_dir]} {return}
    
    set desktop_files [glob -nocomplain -directory $cat_dir "*.desktop"]
    if {[llength $desktop_files] == 0} {return}
    
    set matched_buttons {}
    foreach desktop_file $desktop_files {
        set info [parse_desktop_file $desktop_file]
        set app_name [dict get $info name]
        set exec_cmd [dict get $info exec]
        set icon [dict get $info icon]
        
        if {$app_name eq "" || $exec_cmd eq ""} {continue}
        
        set name_lower [string tolower $app_name]
        set query_lower [string tolower $query]
        if {[string match "*$query_lower*" $name_lower]} {
            lappend matched_buttons [list $app_name $exec_cmd $icon $desktop_file]
        }
    }
    
    set total_buttons [llength $matched_buttons]
    if {$total_buttons == 0} {return}
    
    update idletasks
    set win_width [winfo width $main.buttons.canvas]
    if {$win_width <= 1} {set win_width [expr {[winfo screenwidth .main] - 100}]}
    
    set max_cols [expr {max(1, ($win_width - 2*$padding) / ($btn_width + $padding))}]
    set rows [expr {($total_buttons + $max_cols - 1) / $max_cols}]
    
    set canvas_width $win_width
    set canvas_height [expr {$rows * ($btn_height + 20 + $padding) + $padding}]
    $main.buttons.canvas configure -scrollregion "0 0 $canvas_width $canvas_height"
    $main.buttons.canvas configure -width $win_width
    
    set i 0
    foreach btn_info $matched_buttons {
        lassign $btn_info app_name exec_cmd icon desktop_file
        set row [expr {$i / $max_cols}]
        set col [expr {$i % $max_cols}]
        
        if {$row == $rows - 1 && [expr {$total_buttons % $max_cols}] != 0} {
            set cols [expr {$total_buttons % $max_cols}]
        } else {
            set cols $max_cols
        }
        
        set grid_width [expr {$cols * ($btn_width + $padding) - $padding}]
        set start_x [expr {($win_width - $grid_width) / 2}]
        if {$start_x < $padding} {set start_x $padding}
        
        set x [expr {$start_x + $col * ($btn_width + $padding) + $btn_width/2}]
        set y [expr {$row * ($btn_height + 20 + $padding) + $padding + $btn_height/2}]
        
        set btn [add_app_button $app_name $exec_cmd $icon $desktop_file $main.buttons.canvas $x $y]
        after 0 [list load_icon_async $btn $icon $exec_cmd $app_name $desktop_file]
        incr i
    }
}

proc update_canvas_size {w} {
    global main
    if {![info exists main]} {return}
    set sel [$main.categories.list curselection]
    if {$sel ne ""} {
        load_applications [$main.categories.list get $sel]
    }
}

proc update_cache_on_exit {} {
    save_icon_type_cache
    exit
}

proc clear_search {} {
    global main
    $main.search.entry delete 0 end
    set sel [$main.categories.list curselection]
    if {$sel ne ""} {
        set category [$main.categories.list get $sel]
        fuzzy_search "" $category
    } else {
        $main.categories.list selection set 0
        $main.categories.list activate 0
        load_applications "Рабочий стол"
    }
}

proc toggle_settings_panel {} {
    global main settings_panel_visible
    if {$settings_panel_visible} {
        pack forget $main.categories.refresh
        pack forget $main.categories.settings
        $main.categories.toggle configure -text "v"
        set settings_panel_visible 0
    } else {
        pack $main.categories.refresh -side bottom -fill x -padx 5 -pady 5
        pack $main.categories.settings -side bottom -fill x -padx 5 -pady 5
        $main.categories.toggle configure -text "^"
        set settings_panel_visible 1
    }
}

proc toggle_categories_panel {} {
    global main categories_panel_visible
    if {$categories_panel_visible} {
        pack forget $main.categories
        $main.buttons.panel_toggle configure -text ">"
        set categories_panel_visible 0
    } else {
        pack $main.categories -side left -fill y -padx 5 -pady 5 -before $main.buttons
        $main.buttons.panel_toggle configure -text "<"
        set categories_panel_visible 1
    }
    update idletasks
    update_canvas_size $main.buttons.canvas
}

if {[lindex $argv 0] eq "--update-cache"} {
    create_directories
    build_cache
    save_icon_type_cache
    exit
}

load_config
load_icon_type_cache
create_directories
create_placeholder_icon
initialize_cache

set main [toplevel .main]
wm title $main "Application Launcher"
catch {wm attributes $main -zoomed 1}

set font_width [font measure TkDefaultFont "Рабочий стол"]
set panel_width [expr {$font_width + 20}]
frame $main.categories -width $panel_width
listbox $main.categories.list -width 0
pack $main.categories.list -fill y -expand true
foreach {cat _} $categories {
    $main.categories.list insert end $cat
}

button $main.categories.toggle -text "v" -command {toggle_settings_panel} -relief flat -activebackground "#e0e0e0"
pack $main.categories.toggle -side bottom -fill x -padx 5 -pady 2
bind $main.categories.toggle <Enter> {%W configure -background "#e0e0e0"}
bind $main.categories.toggle <Leave> {%W configure -background [dict get $::config Layout bg_left]}

button $main.categories.refresh -text "Обновить кэш" -command {check_for_new_desktop_files} -relief flat -activebackground "#e0e0e0"
bind $main.categories.refresh <Enter> {%W configure -background "#e0e0e0"}
bind $main.categories.refresh <Leave> {%W configure -background [dict get $::config Layout bg_left]}

button $main.categories.settings -text "Настройки" -command {open_settings} -relief flat -activebackground "#e0e0e0"
bind $main.categories.settings <Enter> {%W configure -background "#e0e0e0"}
bind $main.categories.settings <Leave> {%W configure -background [dict get $::config Layout bg_left]}

frame $main.buttons
pack $main.buttons -side right -fill both -expand true -padx 5 -pady 5
button $main.buttons.panel_toggle -text ">" -command {toggle_categories_panel} -relief flat -activebackground "#e0e0e0"
pack $main.buttons.panel_toggle -side left -fill y -padx 5 -pady 5
bind $main.buttons.panel_toggle <Enter> {%W configure -background "#e0e0e0"}
bind $main.buttons.panel_toggle <Leave> {%W configure -background [dict get $::config Layout bg_right]}

frame $main.search -pady 5
pack $main.search -side top -fill x -in $main.buttons
frame $main.search.spacer
pack $main.search.spacer -side left -expand true

frame $main.search.entry_frame -borderwidth 1 -relief groove -background [dict get $config Layout selection_color]
pack $main.search.entry_frame -side left -padx 5
entry $main.search.entry -width 30 -borderwidth [dict get $config Layout search_entry_border_width] -relief flat -background white
pack $main.search.entry -side left -in $main.search.entry_frame -fill x -expand true -pady 0
button $main.search.clear -text "X" -width 2 -relief flat -borderwidth 1 -background "#f0f0f0" -activebackground "#e0e0e0" -command {clear_search}
pack $main.search.clear -side right -in $main.search.entry_frame -padx 1 -pady 1

frame $main.search.spacer2
pack $main.search.spacer2 -side left -expand true

canvas $main.buttons.canvas -yscrollcommand "$main.buttons.scroll set"
scrollbar $main.buttons.scroll -orient vertical -command "$main.buttons.canvas yview"
pack $main.buttons.scroll -side right -fill y
pack $main.buttons.canvas -side left -fill both -expand true

if {$::tcl_platform(platform) eq "windows"} {
    bind $main.buttons.canvas <Control-MouseWheel> {update_scale %D}
    bind $main.buttons.canvas <MouseWheel> {%W yview scroll [expr {-%D / 120 * 4}] units}
} else {
    bind $main.buttons.canvas <Control-Button-4> {update_scale 120}
    bind $main.buttons.canvas <Control-Button-5> {update_scale -120}
    bind $main.buttons.canvas <Button-4> {%W yview scroll -4 units}
    bind $main.buttons.canvas <Button-5> {%W yview scroll 4 units}
}

bind $main.search.entry <Button-1> {
    global main
    set sel [$main.categories.list curselection]
    if {$sel eq ""} {
        $main.categories.list selection set 0
        $main.categories.list activate 0
        load_applications "Рабочий стол"
    }
    focus %W
}

bind $main.categories.list <<ListboxSelect>> {
    set sel [%W curselection]
    if {$sel ne ""} {
        load_applications [%W get $sel]
    }
}

bind $main.search.entry <KeyRelease> {
    global main
    set sel [$main.categories.list curselection]
    if {$sel eq ""} {
        $main.categories.list selection set 0
        $main.categories.list activate 0
        set category "Рабочий стол"
        load_applications $category
    } else {
        set category [$main.categories.list get $sel]
    }
    set query [$main.search.entry get]
    fuzzy_search $query $category
}

bind $main.buttons.canvas <Configure> {update_canvas_size %W}
bind $main.search.clear <Enter> {%W configure -background "#e0e0e0"}
bind $main.search.clear <Leave> {%W configure -background "#f0f0f0"}
wm protocol $main WM_DELETE_WINDOW {update_cache_on_exit}

update idletasks
apply_scale
apply_colors
$main.categories.list selection set 0
$main.categories.list activate 0
load_applications "Рабочий стол"
event generate $main.categories.list <<ListboxSelect>>

tkwait window $main

#part--7