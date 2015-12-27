namespace eval ::add:: {

setudef flag addit

set addVersion v0.6
set addFile "definitions.db"

bind pubm -|- "*" ::add::handler

proc handler { nick mask hand channel args } {
	if {[channel get $channel addit] && [onchan $nick $channel]} {
		set args [lindex $args 0]
		switch -nocase [lindex [split $args] 0] {
			"!add"		{ putquick "NOTICE $nick :[add [lindex [split $args] 1] $nick [lrange [split $args] 2 end]]"}
			"!expl"		{ putquick "PRIVMSG $channel :[join [expl [lindex $args 1]]]" }
			"!rexpl"	{ putquick "PRIVMSG $channel :[join [rexpl [lindex $args 1]]]" }
			"!author"	{ putquick "PRIVMSG $channel :[join [author [lindex $args 1]]]" }
			"!db"		{ putquick "PRIVMSG $channel :[db]" }
			"!ls"		{ set results [ls [lindex $args 1]]; foreach item $results { putquick "NOTICE $nick :$item" } }
		}
	}
}

proc ls args {
	if {[string length [join $args]]} {
		set text [readAddFile]
		# get titles
		foreach item $text { lappend title [lindex $item 1] }
		# get matches
		foreach item $title { if {[regexp $args $item]} { lappend results $item } }
		set counter 0
		while {[info exists results] && [llength $results] && $counter < 10} {
			set output ""
			if {$counter == 0} { set output "{Showing results for '$args'}" } else { set output "" }
			while {[string length $output] < 380 && [llength $results]} {
				if {[llength [lindex $results 1]]} { lappend output [lindex $results 1] }
				set results [lreplace $results 0 0]
			}
			lappend finalOutput [join $output ", "]
			set counter [expr $counter + 1]
		}
		if {[info exists finalOutput]} { return $finalOutput }
	}
}

proc rexpl { args } {
	set text [readAddFile]
	set results ""
	set keyWord false
	variable rexplHistory
	variable rexplHistoryCount
	if {[string length $args] > 2} {
		foreach item $text {
			if {[regexp -nocase $args $item]} {
				lappend results $item
				set keyWord true
			}
		}
		if {![llength $results]} { set results $text }
	} else { set results $text }
	set randomRexpl [randnum [llength $results]]
	
	if {!$keyWord} {
		set iter 0
		while {![lsearch rexplHistory $randomRexpl]} {
			set randomRexpl [randnum [llength $results]]
			incr iter
			if {$iter > 10000} {
				putlog "error! too many iterations! (addit.tcl)"
				break
			}
		}
		lappend rexplHistory $randomRexpl
		if {[llength $rexplHistory] > $rexplHistoryCount} { set rexplHistory [lreplace $rexplHistory 0 0] }
	}
	set rexpl [lindex $results $randomRexpl]
	return [output $rexpl]
}

proc expl args {
	if {![string length $args]} { return }
	set text [readAddFile]
	foreach item $text {
		if {[string match -nocase $args [lindex $item 1]]} { return [output $item] }
	}
}

proc add args {
	if {![string length $args]} { return }
	if {![llength [expl [lindex [join $args] 0]]]} {
		return [writeAddFile [join $args]]
	} else {
		return "'[lindex [join $args] 0]' already exists" }
}

proc author args {
	if {![string length $args]} { return }
	set text [readAddFile]
	foreach item $text {
		if {[regexp -nocase $args $item]} {
			set addTime [lindex $item 0]; set addTitle [lindex $item 1]; set addNick [lindex $item 2]
			return "'$addTitle' was added by $addNick at [clock format $addTime -format "%d %b %Y, %H:%M"]"
}	}	}

proc db {} {
	set text [readAddFile]
	return "I have [llength $text] quotes in my database"
}

proc writeAddFile args {
	if {![string length $args]} { return }
	variable addFile
	set text "[clock seconds] [lindex [join $args] 0] [lindex [join $args] 1] [lrange [join $args] 2 end]"
	set fileHandler [open $addFile a]
	puts $fileHandler $text
	close $fileHandler
	return "'[lindex [join $args] 0]' added"
}

proc readAddFile {} {
	variable addFile
	set fileHandler [open $addFile r]
	set text [split [read $fileHandler] "\n"]
	close $fileHandler
	if {![llength [lindex $text end]]} {set text [lrange $text 0 end-1]}
	return $text
}

proc output { args } {
	set title [lindex [join $args] 1]
	set quote [lrange [join $args] 3 end]
	return "'$title': $quote"
}

proc randnum { length } {
	return [lindex [split [expr floor(rand() * $length)] .] 0]
}

set rexplHistoryCount [expr [llength [readAddFile]] / 2]
set rexplHistory {}

putlog "Addit.tcl by T-101 $addVersion loaded!"

}
