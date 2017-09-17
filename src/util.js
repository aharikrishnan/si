var resp = {};
fs.readFile('/mnt/data/utils/gem/softwareinsider/data/search.out', 'utf8', function (err,data) {
  if (err) {
    return console.log(err);
  }
  resp = JSON.parse(data);
});
