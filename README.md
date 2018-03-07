# rtags-doxygen.el

## Introduction

rtags-doxygen.el creates doxygen comment at point. It uses RTags to parse the c/c++ source codes, and yasnippet to let the user enter missing field manually.

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
  
