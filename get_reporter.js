var reporterVal = document.getElementById('reporter-val');    
var textContent = reporterVal.querySelector('.user-hover-replaced').childNodes;
var reporterName = Array.from(textContent).find(node => node.nodeType === Node.TEXT_NODE && node.textContent.trim().length > 0).textContent.trim();
document.currentScript.output = reporterName;