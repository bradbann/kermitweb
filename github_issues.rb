#!/usr/bin/ruby

require 'rubygems'
require 'curb'
require 'json'

F=File.open('source/code/issues.md','w')
repo = "https://api.github.com/users/kermitfr/repos"

def mdwrite(s) 
    F.write("#{s}\n")
end

header = <<EOT
---
layout: page
title: "issues"
comments: true
sharing: true
footer: true
sidebar: false 
---

Issues extracted from GitHub.

Last updated :  #{Time.now.strftime("%Y-%m-%d")}

EOT

mdwrite(header)

repos = JSON.parse(Curl.get(repo).body_str)

repos.each do |repo|
  mdwrite("## #{repo['name']}") 
  get_issues = Curl.get("https://api.github.com/repos/#{repo['full_name']}/issues")
  arr_issues = []

  issues = JSON.parse(get_issues.body_str)

  if issues.length < 1
      mdwrite("No issue.") 
  else
    mdwrite("| Issue name | Label       ")
    mdwrite("|:-----------|:------------")
  end

  issues.each do |issue|
    label = "none"
    if issue.has_key?("labels") and issue["labels"][0]
        label = issue["labels"][0]["name"]
    end
    mdwrite("| #{issue["title"]} | #{label}")
  end

  mdwrite("\n")
end
