document.addEventListener('DOMContentLoaded', () => {
  const inlineCode = document.querySelectorAll('code.inline')

  for (let c in inlineCode) {
    if (inlineCode[c].classList) { 
      inlineCode[c].classList.add('language-js')
    }
  }
})
