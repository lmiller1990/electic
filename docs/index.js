document.addEventListener('DOMContentLoaded', () => {
  const titles = document.querySelectorAll('a.is-post')

  for (const title of titles) {
    const titleText = title.text.trim()
    const titleOnly = titleText.substr(9)
    const formattedDate = formatDate(titleText)

    title.text = `${formattedDate} - ${titleOnly}`
  }
})

const formatDate = (title) => {
  const date = title.substr(0, 8)
  const year = date.substr(0, 4)
  const month = getShortMonth(date.substr(4, 2))
  const day = date.substr(6, 2)

  return `${day} ${month} ${year}` 
}

const getShortMonth = (month) => {
  switch (month) {
    case '01':
      return 'Jan'
    case '02':
      return 'Feb'
    case '03':
      return 'March'
    case '04':
      return 'April'
    case '05':
      return 'May'
    case '06':
      return 'June'
    case '07':
      return 'July'
    case '08':
      return 'Aug'
    case '09':
      return 'Sep'
    case '10':
      return 'Oct'
    case '11':
      return 'Nov'
    case '12':
      return 'Dec'
  }
}
