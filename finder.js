
var TJBot = require('tjbot');

var tj = new TJBot(["camera"], {}, {
  visual_recognition: {
    apikey: 'WGF3AclDX0VNyb14enT4mzOdQWOKhzGhruNkd1aQat0R',
    url: 'https://api.us-south.visual-recognition.watson.cloud.ibm.com/instances/96e2f763-6bb2-4b4e-b452-d0ff14ace355'
  }
});

async function loop_see() {
while (1) {
await new Promise(r => setTimeout(r,2000));
tj.see(["default"]).then(objects => {
        console.log(objects);
    objects.forEach(function(entry) {
        if( entry.class == "grasshopper" | entry.class == "locust") {
        console.log("found");
        }
        else {
        console.log("not found");
        }
        });
})
}
}

loop_see();
