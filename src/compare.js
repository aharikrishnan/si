/**
 * Copyright 2017 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const mongoose = require('mongoose');

(async() => {

  const launchSettings = {
    headless: false,
    ignoreHTTPSErrors: true,
    timeout:60000,
    //executablePath: '/usr/bin/google-chrome'
    //headless: true,
    //args: ['--ignore-certificate-errors']
  };
  const browser = await puppeteer.launch(launchSettings);
  const page = await browser.newPage();
  await page.setRequestInterceptionEnabled(true);
  page.on('request', request => {
    //Document, Stylesheet, Image, Media, Font, Script, TextTrack, XHR, Fetch, EventSource, WebSocket, Manifest, Other
    if (
      request.resourceType === 'Document' ||
      request.resourceType === 'Script' ||
      request.resourceType === 'XHR'
      )
    request.continue();
    else
    request.abort();
  });
  const startURL = process.env['CMP_URL']
  const cmpPage = process.env['CMP_PAGE']
  //"http://project-management.softwareinsider.com/compare/68-82-194-205-313-624-630-633-643-659-694-740-758-766-816-851-852-853/x";
  await page.goto(startURL, {
   //waitUntil: 'networkidle'
  });
  // Type our query into the search bar
  //await page.type('puppeteer');

  //await page.click('input[type="submit"]');

  // Wait for the results to show up
  //await page.waitForSelector('h3 a');
  var writeToFile = function (name, json) {
    var filePath = path.join(__dirname, '..', "data", name + ".json");
    fs.writeFile(filePath, JSON.stringify(json), function (err) {
      if (err) {
        return console.log(err);
      }
      console.log("The file was saved at " + filePath);
    });
  }
  var writeToCSV = function (name, tbl) {
    console.log(name);
    var filePath = path.join(__dirname, '..', "data", name + ".csv");
    var csv = "";
    console.log(tbl.length)
    for (var i in tbl) {
      var r = tbl[i].join("\t");
      csv = csv + r + "\n"
    }
    fs.writeFile(filePath, csv, function (err) {
      if (err) {
        return console.log(err);
      }
      console.log("The file was saved at " + filePath);
    });
  }

  //await page.addScriptTag("https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.0/jquery.min.js");
  var jq = path.join(__dirname, '..', "src", "jquery.min.js");
  await page.injectFile(jq)
    
  await page.waitFor(8000);

  const features = await page.evaluate(() => {
    //const anchors = Array.from(document.querySelectorAll('h3 a'));
    //return anchors.map(anchor => anchor.textContent);
    var header = ["feature_group", "feature"];
    var items = $('.c-header .cell .c-dd-link').map(function () {
      var me = $(this);
      var n = me.text(),
        h = me.attr('href');
      header.push(n);
      return {
        name: n,
        href: h
      };
    }).get();
    var f = {};
    var features = $('.stnd-sec.collapsible').filter(function () {
      var n = $(this).find('.stnd-sec-title>.stnd-sec-title-txt').text();
      console.log(n);
      return n == 'Features'
    })

    features.find('.show-same').each(function () {
      var wrap = $(this);
      var fname = $.trim(wrap.find(" > .title > .title-text").text());
      console.log("--->", fname);
      var lists = wrap.find('.data-wrap .cell')
      lists.each(function (i, _) {
        var row = [];
        row.push(fname)
        var list = $(this);
        var item = items[i];
        console.log(i, items)
        var h = {};
        list.find('li').each(function (i, v) {
          var me = $(this);
          var n = $.trim(me.text());
          var bool = me.hasClass('feature');
          var num = bool ? 1 : 0;
          h[n] = bool;
          row.push(n)
          row.push(num)
        })
        f[fname] = f[fname] || [];
        f[fname].push(h)
      })
    });

    return [items, f];
  });

  //var fileName = startURL.split("//", 2)[1].split("/")[2].split("-").map(function(v,i){return parseInt(v,10);}).sort((a, b) => a - b).join("-");
  var fileName = cmpPage;
  var dir = startURL.split("//", 2)[1].split('.')[0];

  writeToFile(dir+'/itm.'+fileName, features[0])
  writeToFile(dir+'/feat.'+fileName, features[1])

  var tbl1 = [];
  //var header = ( cmpPage === '0' )? ["feature_group", "feature"] : [];
  var header = ["feature_group", "feature"]
  for (var n in features[0]) {
    header.push(features[0][n].name);
  }
  tbl1.push(header);
  for (var fn in features[1]) {
    var keys = features[1][fn][0];
    for (var k in keys) {
      //var row = ( cmpPage === '0' )? [fn, k] : [];
      var row = [fn, k];
      for (var i in features[1][fn]) {
        var val = features[1][fn][i][k]
        row.push((val)?1:0);
      }
      tbl1.push(row);
    }
  }
  writeToFile(dir+'/tbl.'+fileName, tbl1)
  writeToCSV(dir+'/cmp.'+fileName, tbl1)

  browser.close();

})();
