# Description     
vocabook is a Vim plugin which provides a contextual way for building vocabulary, the very first step of writing learning. Inspired by the staged-modified-and-committed vocabulary development mechanism taught in the MOOC named Principles of Written English, I created the tool by which users can glean words effectively using techniques such as categorizing, taking notes, collocating, using mnemonics and spaced repeating and etc.     

# Prerequisite   
Making sure that Python and MySQL is installed.   
NLTK is needed.

# Installation   
Copy plugin/vocabook to ~/.vim/plugin   
Or add a GitHub repository entry if you are using a Plugin Manager such as Vundle:  
```Plugin 'eduOS/vocabook'```

# Configuration   
Change the database and password to your own.   
    
# Functions    
0. Word extracting       
    Pressing the key combination ```<leader>V``` will bring the user to a new window with the word under the cursor stored in a register.    
1. Lemmatizing       
    Words are lemmatized such that words in different inflected forms are recorded as the same non-inflected form.      
    Different meanings for the same non-inflected word are listed for choosing, with a mark of whether the word has been collected and its tags. The user will see the main window by intuitively pressing Enter.    
2. Tagging      
    To aid in words retrieval, words can be tagged by multiple tags. Tags can be modified later.    
3. collecting excerpts       
    The sentence under the cursor will be copied and then added to the database. If a certain meaning of a non-inflected word is looked up the second time or later the sentence is checked if it has been in the database, if not it is added; else it is discarded.     
4. Sentence making     
    Practice is a way of learning by doing.     
5. Looking up for detailed information    
    As a vocabulary book in nature this plugin provides brief information that almost every dictionary can offer. Pressing ```<leader>d``` will do that.    

# Screenshots
![list](https://cloud.githubusercontent.com/assets/5717031/11235957/cbda86ca-8e10-11e5-8bc5-6c1c3698feb5.png)  
![details](https://cloud.githubusercontent.com/assets/5717031/11236982/f70dd0d4-8e17-11e5-8ea3-66901dabe46d.png)  
    
# Todo    
- [ ] normal command line search by tag and anything with results categorized    
- [x] go back to the exact location after copying the sentence.    
- [ ] highlight the background of the line the cursor is in    
- [ ] optimize the tag management mathord    
- [x] auto insert after loading the second detail window    
- [ ] phrase adding and collocation adding(auto collocate) in visual mode    
- [ ] collocation recoganize in a sentence    
- [ ] collocation search    
- [ ] more detailed explanation from wordnet    
- [ ] passage reading and review writing using Git and issue: hash generate and reference    
- [x] show the number and related words on the first level window    
- [ ] autocomplete when editing by searching tags and words in sentences, then optimize the algorithm    
- [ ] review    
- [ ] backwards navigable: hackernews    
- [ ] delete word and accordingly the tags    
- [ ] youdao wordbook import    
- [ ] highlight all vocabulary dumped    
- [ ] filter text for plain, clear and whole sentence    
- [ ] modify database to record collocation manually and definition automatically    
- [ ] more example sentences extracted from open data    
    
# License     
MIT    
