######################### # # #
###
###	Addit - a quote database for eggdrop bots
###
###	Usage: load addit.tcl to your bot and add featured channel(s)
###	from the bots partyline: .chanset #channel +addit
###
###	Public commands:
###	!expl topic		- Display specific quote
###	!rexpl [searchword]	- Display random quote, optional searchword can be included
###	!add topic free text	- Add quote to database
###	!ls searchword		- Search for topics using searchword
###	!author topic		- Display quote author and date
###	!db			- Display number of quotes in database
###
###	Version history:
###	v0.1	First version
###	v0.2	Added date to quotes
###	v0.5	First rewrite after server and sourcecode went boom
###	v0.6	Fixes to randomizer, added !rexpl searchword, !rexpl now has a history to avoid dupes being displayed
###	v0.7	Database now forced to UTF-8, fixed longstanding brainlessness of TCL strings vs lists (thx dogo)
###
###	2016 T-101 / Primitive ^ Darklite
###
###	Use with own risk. I take responsibility for absolutely nothing.
###

namespace eval ::add:: {

setudef flag addit

set addVersion v0.7
set addFile "definitions.db"

if {![file exists $addFile]} {
	set fh [open $addFile w]
	close $fh
	putlog "file $addFile created"
}

bind pubm -|- "*" ::add::handler

set reFileParse {(\S+)\s(\S+)\s(\S+)\s(.*)}

proc handler { nick mask hand channel args } {
	if {[channel get $channel addit] && [onchan $nick $channel]} {
		regexp {(\S+)\s?(.*)} [join $args] -> command params
		if {![info exists command]} { return }
		switch -nocase $command {
			"!add"		{ putquick "NOTICE $nick :[add $nick $params]" }
			"!expl"		{ putquick "PRIVMSG $channel :[expl [lindex $params 0]]" }
			"!rexpl"	{ putquick "PRIVMSG $channel :[rexpl [lindex $params 0]]" }
			"!author"	{ putquick "PRIVMSG $channel :[author [lindex $params 0]]" }
			"!db"		{ putquick "PRIVMSG $channel :[db]" }
			"!ls"		{ set results [ls [lindex $params 0]]; foreach item $results { putquick "NOTICE $nick :$item" } }
		}
	}
}

proc ls args {
	if {[string length [join $args]]} {
		variable reFileParse
		set text [readAddFile]
		# get titles
		foreach item $text { lappend title [regsub $reFileParse $item {\2}] }
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
		if {[string match -nocase $args [regsub {(\S+)\s(\S+)\s(.*)} $item {\2}]]} { return [output $item] }
	}
}

proc add args {
	if {![string length $args]} { return }
	regexp {(\S+)\s(\S+)\s(.*)} [join $args] -> nick topic add
	if {![llength [expl $topic]]} {
		return [writeAddFile $topic $nick $add]
	} else {
		return "'${topic}' already exists" }
}

proc author args {
	if {![string length $args]} { return }
	variable reFileParse
	set text [readAddFile]
	foreach item $text {
		if {[regexp -nocase $args $item]} {
			regexp $reFileParse $item -> addTime addTitle addNick
			return "'$addTitle' was added by $addNick at [clock format $addTime -format "%d %b %Y, %H:%M"]"
}	}	}

proc db {} {
	set text [readAddFile]
	return "I have [llength $text] quotes in my database"
}

proc writeAddFile {topic nick add} {
	variable addFile
	set text "[clock seconds] $topic $nick $add"
	set fileHandler [open $addFile a]
	fconfigure $fileHandler -encoding utf-8
	puts $fileHandler $text
	close $fileHandler
	return "'$topic' added"
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
	variable reFileParse
	regexp $reFileParse [join $args] -> -> title -> quote
	return "'$title': $quote"
}

proc randnum { length } {
	return [lindex [split [expr floor(rand() * $length)] .] 0]
}

set rexplHistoryCount [expr [llength [readAddFile]] / 2]
set rexplHistory {}

putlog "Addit.tcl by T-101 $addVersion loaded!"

}
