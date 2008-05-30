/* Code editor */

function autoindent(e) {
  var k = e.keyCode || e.charCode;
  if (k != 13) return true;
  e.preventDefault();
  var range = $(this).getSelection();
  var pos = range.start;
  var ws = $(this).val().substr(0,pos);
  ws = ws.match(/(^|\n)([ ]*)[^\n]*$/);
  ws = ws[2];
  ws = "\n" + ws;
  $(this).replaceSelection(ws);
  $(this).setSelection({pos: pos + ws.length});
}


