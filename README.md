elien
=====

A tool to generate Gentoo ebuilds from various sources

Named after the alien tool from Debian.

GOAL
====

The goal of this project is to create a tool that can be used to easily create
Gentoo ebuilds from various sources.

Prototype:
----------

Hackish proof-of-concept bash script to explore what we need. Maybe refactor
later to a real language

Milestone 1: Web-based ebuild generation
----------------------------------------
sourceforge.net, the Debian project and other well-known web sites all have
information which can be used to extract information about their hosted
software.

elien should use this information to fill in the metadata bits in an ebuild

Milestone 2: handle different build and install systems
-------------------------------------------------------
Primarily should fill in ebuild inherit and build info

    Examples: autotools, boost-build, scons, Python ...

Milestone 3: true alien
-----------------------

Where available, build info from other packages should be converted to ebuilds.

    Examples: .deb has the debian/rules and other build instructions
              .rpm has .spec files
              Arch AUR/PKGBUILD files are poor-mans ebuilds anyway
