package main

import (
	sp "github.com/kpkhxlgy0/gs_libs/services"
)

func startup() {
	go sig_handler()
	// init services discovery
	sp.Init("game", "snowflake")
}
