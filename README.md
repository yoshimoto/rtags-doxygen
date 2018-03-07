# rtags-doxygen.el

## Introduction

rtags-doxygen.el is an Emacs package for writing [doxygen](http://www.doxygen.org/) comment. It uses [RTags](https://github.com/Andersbakken/rtags) to parse the c/c++ source codes, and [yasnippet](https://github.com/joaotavora/yasnippet) to let the user enter missing field manually.

## Usage

Add the following lines in your .emacs file.

~~~~~elisp
(require 'rtags-doxygen)
(add-hook 'c-mode-common-hook 'rtags-doxygen-mode)
~~~~~

Default key bindings are:
- `C-c d i` will insert doxygen comment at the point.
  + When invoked to the symbol such as function/class/struct, it inserts a template of doxygen documentation.
  + When invoked at the beggining of the source code, it inserts file header.
  
