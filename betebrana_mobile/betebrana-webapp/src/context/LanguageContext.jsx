import { createContext, useContext, useState, useEffect } from 'react';

const translations = {
  en: {
    // Nav & General
    "Home": "Home",
    "Discover": "Discover",
    "My Library": "My Library",
    "Search": "Search",
    "Profile": "Profile",
    "Settings": "Settings",
    "My Account": "My Account",
    "Sign In": "Sign In",
    "Sign Out": "Sign Out",
    "Dark Theme": "Dark Theme",
    "App Language": "App Language",
    "Manage your profile and personal preferences": "Manage your profile and personal preferences",
    "Currently enabled — dark mode is on": "Currently enabled — dark mode is on",
    "Currently disabled — using light mode": "Currently disabled — using light mode",
    "Choose your preferred interface language": "Choose your preferred interface language",
    "Library": "Library",
    "My Rentals & History": "My Rentals & History",
    "View your active books and reading history": "View your active books and reading history",
    "Preferences": "Preferences",
    "You are not logged in": "You are not logged in",
    "Go to Login": "Go to Login",
    
    // HomePage
    "New Arrivals": "New Arrivals",
    "Browse by Category": "Browse by Category",
    "Your digital library. Borrow, discover, and read anytime.": "Your digital library. Borrow, discover, and read anytime.",
    "Find the perfect book for ": "Find the perfect book for ",
    "every moment.": "every moment.",
    "Borrow books easily, explore curated collections, and enjoy reading anytime, anywhere.": "Borrow books easily, explore curated collections, and enjoy reading anytime, anywhere.",
    "Borrow Now": "Borrow Now",
    "Browse Collection": "Browse Collection",
    "Titles": "Titles",
    "Readers": "Readers",
    "Curated for you": "Curated for you",
    "Popular Books This Week": "Popular Books This Week",
    "Explore More ": "Explore More ",
    "Available": "Available",
    "Borrowed": "Borrowed",
    "View Details": "View Details",
    "Dive into your favorite genres and discover new topics.": "Dive into your favorite genres and discover new topics.",
    "Details": "Details",
    "Providing accessible reading materials and curated collections for learners and enthusiasts.": "Providing accessible reading materials and curated collections for learners and enthusiasts.",
    "Platform": "Platform",
    "Browse Library": "Browse Library",
    "Trending Now": "Trending Now",
    "Support": "Support",
    "Help Center": "Help Center",
    "Contact Us": "Contact Us",
    "System Status": "System Status",
    "Legal": "Legal",
    "Terms of Service": "Terms of Service",
    "Privacy Policy": "Privacy Policy",
    "BeteBrana Digital Library. All rights reserved.": "BeteBrana Digital Library. All rights reserved.",

    // SearchPage
    "Titles, authors, or topics...": "Titles, authors, or topics...",
    "Popular Authors": "Popular Authors",
    "Trending Books": "Trending Books",
    "Results for": "Results for",
    "Explore Complete Library": "Explore Complete Library",
    "titles available": "titles available",
    "Loading library...": "Loading library...",
    "No books matched your search.": "No books matched your search.",

    // LibraryPage
    "My Rentals": "My Rentals",
    "Wishlist": "Wishlist",
    "Downloaded": "Downloaded",
    "Loading your library…": "Loading your library…",
    "You have no active rentals right now.": "You have no active rentals right now.",
    "Your wishlist is empty.": "Your wishlist is empty.",
    "No books downloaded for offline reading.": "No books downloaded for offline reading.",
    "Open": "Open",

    // BookDetailsPage
    "Loading Book…": "Loading Book…",
    "Book not found.": "Book not found.",
    "Read Now": "Read Now",
    "Rent (Reserved)": "Rent (Reserved)",
    "in Queue": "in Queue",
    "Borrow Book": "Borrow Book",
    "Join Queue": "Join Queue",
    "Book Details": "Book Details",
    "copies available": "copies available",
    "All copies borrowed — join queue": "All copies borrowed — join queue",
    "Synopsis": "Synopsis",
    "No synopsis available for this book yet. Dive in and start reading!": "No synopsis available for this book yet. Dive in and start reading!",
    "You Might Also Like": "You Might Also Like",
    "View all": "View all",
    "Borrow": "Borrow",
    "Please wait…": "Please wait…"
  },
  am: {
    // Nav & General
    "Home": "ዋና ገጽ",
    "Discover": "አስስ",
    "My Library": "የእኔ ቤተ-መጽሐፍት",
    "Search": "ፈልግ",
    "Profile": "መገለጫ",
    "Settings": "ቅንብሮች",
    "My Account": "የእኔ መለያ",
    "Sign In": "ግባ",
    "Sign Out": "ውጣ",
    "Dark Theme": "ጥቁር ገጽታ",
    "App Language": "የመተግበሪያ ቋንቋ",
    "Manage your profile and personal preferences": "መገለጫዎን እና የግል ምርጫዎችዎን ያቀናብሩ",
    "Currently enabled — dark mode is on": "በአሁኑ ጊዜ ነቅቷል - ጥቁር ሁነታ በርቷል",
    "Currently disabled — using light mode": "በአሁኑ ጊዜ ተሰናክሏል - ነጭ ሁነታን በመጠቀም",
    "Choose your preferred interface language": "የሚመርጡትን የበይነገጽ ቋንቋ ይምረጡ",
    "Library": "ቤተ-መጽሐፍት",
    "My Rentals & History": "የእኔ ኪራዮች እና ታሪክ",
    "View your active books and reading history": "ገቢር መጽሐፍትዎን እና የንባብ ታሪክዎን ይመልከቱ",
    "Preferences": "ምርጫዎች",
    "You are not logged in": "አልገቡም",
    "Go to Login": "ወደ መግቢያ ይሂዱ",

    // HomePage
    "New Arrivals": "አዳዲስ መጽሐፍት",
    "Browse by Category": "በምድብ አስስ",
    "Your digital library. Borrow, discover, and read anytime.": "የእርስዎ ዲጂታል ቤተ-መጽሐፍት። በማንኛውም ጊዜ ይዋሱ፣ ያስሱ እና ያንብቡ።",
    "Find the perfect book for ": "ለእያንዳንዱ ጊዜ ",
    "every moment.": "ትክክለኛውን መጽሐፍ ያግኙ።",
    "Borrow books easily, explore curated collections, and enjoy reading anytime, anywhere.": "መጽሐፍትን በቀላሉ ይዋሱ፣ የተመረጡ ስብስቦችን ያስሱ እና በማንኛውም ጊዜ እና ቦታ በማንበብ ይደሰቱ።",
    "Borrow Now": "አሁን ይዋሱ",
    "Browse Collection": "ስብስብን ያስሱ",
    "Titles": "ርዕሶች",
    "Readers": "አንባቢዎች",
    "Curated for you": "ለእርስዎ የተመረጡ",
    "Popular Books This Week": "በዚህ ሳምንት ታዋቂ መጽሐፍት",
    "Explore More ": "ተጨማሪ ያስሱ ",
    "Available": "ይገኛል",
    "Borrowed": "ተበድሯል",
    "View Details": "ዝርዝሮችን ይመልከቱ",
    "Dive into your favorite genres and discover new topics.": "ወደሚወዷቸው ዘውጎች ይግቡ እና አዳዲስ ርዕሶችን ያግኙ።",
    "Details": "ዝርዝሮች",
    "Providing accessible reading materials and curated collections for learners and enthusiasts.": "ለተማሪዎች እና አድናቂዎች ተደራሽ የሆኑ የማንበቢያ ቁሳቁሶችን እና የተመረጡ ስብስቦችን ማቅረብ።",
    "Platform": "መድረክ",
    "Browse Library": "ቤተ-መጽሐፍትን ያስሱ",
    "Trending Now": "አሁን በመታየት ላይ ያሉ",
    "Support": "ድጋፍ",
    "Help Center": "የእገዛ ማዕከል",
    "Contact Us": "አግኙን",
    "System Status": "የስርዓት ሁኔታ",
    "Legal": "ሕጋዊ",
    "Terms of Service": "የአገልግሎት ውሎች",
    "Privacy Policy": "የግላዊነት መመሪያ",
    "BeteBrana Digital Library. All rights reserved.": "ቤተ-ብራና ዲጂታል ቤተ-መጽሐፍት። መብቱ በህግ የተጠበቀ ነው።",

    // SearchPage
    "Titles, authors, or topics...": "ርዕሶች፣ ደራሲያን ወይም ርዕሰ ጉዳዮች...",
    "Popular Authors": "ታዋቂ ደራሲያን",
    "Trending Books": "በመታየት ላይ ያሉ መጽሐፍት",
    "Results for": "ውጤቶች ለ",
    "Explore Complete Library": "ሙሉ ቤተ-መጽሐፍትን ያስሱ",
    "titles available": "ርዕሶች ይገኛሉ",
    "Loading library...": "ቤተ-መጽሐፍትን በመጫን ላይ...",
    "No books matched your search.": "ከፍለጋዎ ጋር የሚዛመዱ መጽሐፍት የሉም።",

    // LibraryPage
    "My Rentals": "የእኔ ኪራዮች",
    "Wishlist": "የምኞት ዝርዝር",
    "Downloaded": "የወረዱ",
    "Loading your library…": "የእርስዎን ቤተ-መጽሐፍት በመጫን ላይ…",
    "You have no active rentals right now.": "በአሁኑ ጊዜ ምንም ንቁ ኪራዮች የሉዎትም።",
    "Your wishlist is empty.": "የምኞት ዝርዝርዎ ባዶ ነው።",
    "No books downloaded for offline reading.": "ከመስመር ውጭ ለማንበብ ምንም መጽሐፍት አልወረዱም።",
    "Open": "ክፈት",

    // BookDetailsPage
    "Loading Book…": "መጽሐፍ በመጫን ላይ…",
    "Book not found.": "መጽሐፍ አልተገኘም።",
    "Read Now": "አሁን ያንብቡ",
    "Rent (Reserved)": "ይከራዩ (ተይዟል)",
    "in Queue": "በተራ ውስጥ",
    "Borrow Book": "መጽሐፍ ይዋሱ",
    "Join Queue": "ተራ ይቀላቀሉ",
    "Book Details": "የመጽሐፍ ዝርዝሮች",
    "copies available": "ቅጂዎች ይገኛሉ",
    "All copies borrowed — join queue": "ሁሉም ቅጂዎች ተበድረዋል - ተራ ይቀላቀሉ",
    "Synopsis": "ማጠቃለያ",
    "No synopsis available for this book yet. Dive in and start reading!": "ለዚህ መጽሐፍ እስካሁን ምንም ማጠቃለያ የለም። ይግቡ እና ማንበብ ይጀምሩ!",
    "You Might Also Like": "እርስዎም ሊወዱት ይችላሉ",
    "View all": "ሁሉንም ይመልከቱ",
    "Borrow": "ይዋሱ",
    "Please wait…": "እባክዎ ይጠብቁ…"
  }
};

const LanguageContext = createContext();

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');

  useEffect(() => {
    localStorage.setItem('language', language);
  }, [language]);

  const t = (key) => {
    return translations[language]?.[key] || translations['en']?.[key] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  return useContext(LanguageContext);
}
