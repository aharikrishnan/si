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

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const mongoose = require('mongoose');

(async() => {

  const launchSettings = {headless: false};
  const browser = await puppeteer.launch(launchSettings);
  const page = await browser.newPage();
  const startUrl = "http://www.softwareinsider.com/"
  await page.goto(startUrl, {
    waitUntil: 'networkidle'
  });
  // Type our query into the search bar
  //await page.type('puppeteer');

  //await page.click('input[type="submit"]');

  // Wait for the results to show up
  //await page.waitForSelector('h3 a');
  await page.waitFor(2000);
var initMongoose = function(){
  var conn = mongoose.connect('mongodb://localhost:27017/si');

}
  var writeToFile = function (name, json) {
    var filePath = path.join(__dirname, '..', "data", name + ".json");
    fs.writeFile(filePath, JSON.stringify(json), function (err) {
      if (err) {
        return console.log(err);
      }
      console.log("The file was saved at " + filePath);
    });
  }


  // Extract the results from the page
  const categories = await page.evaluate(() => {
    //const anchors = Array.from(document.querySelectorAll('h3 a'));
    //return anchors.map(anchor => anchor.textContent);
    var cats = {};
    $(".np-comps.np-subcat-sec.stnd-sec ").each(function (i, v) {
      var me = $(this);
      var cn = $.trim(me.find('.stnd-sec-title .stnd-sec-title-txt').text());
      var id = me.data('id');

      var cb = me.find('.stnd-sec-body').find('.np-item-wrap-all-text').map(function (i, v) {
        var c = $(this);
        var n = $.trim(c.find('.np-item-title-text').text()),
          l = $.trim(c.find('.hp-topic-evt-link').attr('href'));
        return {
          'name': n,
          "link": l
        }
      }).get();

      cats[cn] = {
        "id": id,
        "child": cb
      };
    })

    return cats;
  });

  console.log(categories);
  writeToFile('categories', categories)
  initMongoose();
  var Schema = mongoose.Schema, ObjectId = Schema.ObjectId;
  var CategoriesSchema = new Schema({
    name: String,
      link: String,
      parent: String,
      parent_id: String,
  });
  var Category = mongoose.model('Category', CategoriesSchema);
  console.log("Here!!")

  for(var cat in categories){
    var p = categories[cat];
  console.log(p)
    for(var i in p.child){
      c = p.child[i]
      var name = c.name, link = c.link;
      var record = {name: name, link: link, parent: cat, parent_id: p.id}
      var c = new Category();
      c.save(function(err){
        if(err){
          return console.log(err);
        }
      })
      console.log(JSON.stringify(record))
    }
  }

  console.log("Here!!")

  browser.close();

})();
