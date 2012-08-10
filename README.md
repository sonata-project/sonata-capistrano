Deploying symfony Applications with Capistrano
==============================================

Warning : This repository contains some code from the capifony project.
          Please found more information here : http://capifony.org

Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. We’ve been working on creating a deployment “recipe” to work with symfony applications to make our job a lot easier.

## Prerequisites ##

- Symfony 1.4+ OR Symfony2
- Must have SSH access to the server you are deploying to.
- Must have Ruby and RubyGems installed on your machine (not required for deployment server)’
- Must have composer file in bin directory (to avoid installation of composer on each server)

## Installing Capistrano ##

### Through RubyGems.org ###

	sudo gem install capistrano

## Setup your project to use Capifony ##

CD to your project directory & run:

	capify .

