// ==UserScript==
// @name          Signal-Desktop (Responsive mode)
// @description	  Signal-Desktop is now responsive
// @authors       Pierre Parent, Adrian Campos Garrido 
// @version       20251009
// @License       AGPL-v3.0
// ==/UserScript==

const X = {
  app: () => document.querySelector("#app-container"),
  browser: () => document.getElementById('app').getElementsByClassName('browser')[0] ,
  mainWrapper: () => document.querySelector('.App'),  
    unkownSection1: () => document.querySelector('.Inbox__no-conversation-open'), 
    chatList: () => document.querySelector('.NavSidebar'),
      chatlistHeader: () => document.querySelector('.NavSidebar__HeaderContent'),
    chatWindow: () => document.querySelector('.Inbox__conversation-stack'),
      chatHeader: () => document.querySelector('.module-ConversationHeader__header'),
      moduleTimelineMessages: () => document.querySelector('.module-timeline__messages__container'),
    preferenceContentWindow: () => document.querySelector('.Preferences__content'),
      preferenceContentHeader: () => document.querySelector('.Preferences__title'),
  //-------------------------------------------------------------------------------------------

  upperWrapper: () => document.querySelector('.three'),
    contactInfo: () => document.querySelector('.three').childNodes[5],
      
  leftMenu: () => document.querySelector('.NavTabs'),
  
  //Landing elements (Only present temporarilly while whatsapp is loading)
  landingWrapper: () => document.querySelector('.landing-wrapper'),
  landingHeader: () => document.querySelector('.landing-header'),
  mainDiv: () =>  document.querySelector("div#main"),
  messageEditor: () => document.querySelector(".CompositionArea"),
  textEditor: () => document.querySelector('.ql-editor'),
  
  buttonActivateLeftMenu: () => X.chatlistHeader().querySelector('.NavTabs__Toggle'),
   buttonDisableLeftMenu: () => X.leftMenu().querySelector('.NavTabs__Toggle'),
   buttonTogleLeftMenuHelper: () => document.querySelector('.NavTabs__ItemLabel')
};

// Declare variables
updatenotificacion = 0;
allownotification = 0;
var lastClickEl=null;
var lastFocusEl=null;
var needToShowChatWindow=0;
var firstChatLoad=1;

//-----------------------------------------------------
//Request by default webnofications permission
//-----------------------------------------------------
Notification.requestPermission();

//-----------------------------------------------------
//            Usefull functions
//-----------------------------------------------------
  function addCss(cssString) {
      var head = document.getElementsByTagName('head')[0];
      var newCss = document.createElement('style');
      newCss.type = "text/css";
      newCss.innerHTML = cssString;
      head.appendChild(newCss);
  }
  
//---------------------------------------------  
// Listeners to startup main()
//---------------------------------------------
window.addEventListener("load", function(event) {
    console.log("Loaded");
    main();
});

const observer = new MutationObserver((mutationsList, obs) => {
  for (const mutation of mutationsList) {
    if (mutation.type === 'childList') {
      if (X.chatList()) {
        obs.disconnect();
        main();
        return;
      }
    }
  }
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});


const STYLE_ID = 'composition-hidden-style';

function addHiddenCSS() {
  if (document.getElementById(STYLE_ID)) return; // idempotent
  const style = document.createElement('style');
  style.id = STYLE_ID;
  style.textContent = `.CompositionArea { visibility: hidden !important; }`;
  document.head.appendChild(style);
}

function removeHiddenCSS() {
  const style = document.getElementById(STYLE_ID);
  if (style) style.remove();
}


//----------------------------------------------------------------------
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//                Main function
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//----------------------------------------------------------------------
function main(){
  console.log("Call main function")
  
  try{
  addCss(".NavSidebar { transition: transform 0.25s ease-in-out !important ; min-width: 100% !important; position: absolute; z-index:1000; }")
  document.documentElement.style.setProperty("--axo-scrollbar-gutter-thin-vertical","6px")
  addCss(".module-timeline__messages__container:not(:hover) {scrollbar-color: transparent transparent;}")
  addCss(".module-timeline__messages__container{ scrollbar-width: thin !important ; }");
  }
  catch (e) {
  console.error(e);
  }
 
  X.chatList().style.minWidth = "100%"
  X.chatWindow().style.minWidth = "100%"
  console.log("Minwith set")
  X.chatList().style.width = "100%"
  X.chatList().style.zIndex = "1000"
  X.chatWindow().style.width = "100%"   
  
    showchatlist(); 
   
   //------------------------------------------------------
   //  Avoid opening the keyboard when entering a chat
  //-------------------------------------------------------
  document.body.addEventListener('focusin', (event) => {
    lastFocusEl = event.target;
    if ( (lastFocusEl.isContentEditable || X.messageEditor().contains(lastFocusEl) ) && (!lastClickEl || ! lastClickEl.isContentEditable ) )
    {
      if (lastFocusEl.contains(X.textEditor()) || lastFocusEl.contains === X.textEditor())
      {
        X.textEditor().removeAttribute('contenteditable');
        X.textEditor().classList.add('contenteditableDisabled');
        X.textEditor().blur();
      }
        lastFocusEl.blur();
    }
    else if ( X.messageEditor().contains(lastFocusEl))
    {
      var keyboardMargin = 12; //px
      var keyboardHeight = Math.round(parseFloat(window.__cmdParams.keyboardHeight) /parseFloat(window.__cmdParams.forceScale)+keyboardMargin);
      X.messageEditor().style.paddingBottom=`${keyboardHeight}px`;
    }
    else
      X.messageEditor().style.paddingBottom=""
    
  });
  
  
  const elements = document.querySelectorAll('.NavSidebar--narrow');

  elements.forEach(el => {
    el.classList.remove('NavSidebar--narrow');
  });
  
  // Créer un observer pour le body
  const observer3 = new MutationObserver((mutations, obs) => {
    
     for (const mutation of mutations) {
    // On s'intéresse aux nouveaux nœuds ajoutés
    mutation.addedNodes.forEach(node => {
      if (node.nodeType === Node.ELEMENT_NODE) {
        // Vérifie si contenteditable est true
        if (node.getAttribute('contenteditable') === 'plaintext-only') {
          console.warn('Suppression d’un élément contenteditable !', node);
          child.removeAttribute('contenteditable');
          X.textEditor().classList.add('contenteditableDisabled');
        }

        // Si le noeud a des descendants, on fait un check récursif
        node.querySelectorAll('[contenteditable="plaintext-only"]').forEach(child => {
          console.warn('Désactivation d’un contenteditable injecté', child);
          child.removeAttribute('contenteditable');
          X.textEditor().classList.add('contenteditableDisabled');
        });
      }
    });
  }
    
    backupBackButton()
    
  });
  // Observe the whole body
  observer3.observe(document.body, {
    childList: true,
    subtree: true
  });  
    
  if ( X.buttonDisableLeftMenu()   && ! document.querySelector(".NavTabs--collapsed") )
     X.buttonDisableLeftMenu().click();
  
  setTimeout( () => { 
    
    if ( X.buttonDisableLeftMenu() && ! document.querySelector(".NavTabs--collapsed") )
     X.buttonDisableLeftMenu().click();
    else
      console.log("NobuttonDisableLeftMenu");
  },1000);
  
  //Disable Over
  ["mouseenter"].forEach(eventType => {
  document.addEventListener(eventType, e => {
    if (e.target.firstChild.classList.contains("NavTabs__ItemButton")&& e.target.parentNode.classList.contains("NavTabs__Toggle"))
        e.stopImmediatePropagation();
  }, true); // useCapture = true pour intercepter avant les autres handlers
  });

}

//---------------------------------------------------------------------
//------------------------------------------------------------
//  Analize JS after every click on APP and execute Actions
//------------------------------------------------------------
//---------------------------------------------------------------------

window.addEventListener("click", function() {
  //Register Last clicked element
  lastClickEl=event.target;  
  console.log(lastClickEl);
   //---------------------------------------------------------------------------------
   //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   // Important section: Handle navigation towards chatWindow
   //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  //----------------------------------------------------------------------------------  
  if (lastClickEl.closest('.module-left-pane__list--measure'))
        showchatWindow();
  else
  {
  if ( X.textEditor() )
    {
    if (X.textEditor().contains(lastClickEl)|| lastClickEl.contains(X.textEditor()))
        {
        X.textEditor().setAttribute('contenteditable', "plaintext-only");
        X.textEditor().classList.remove('contenteditableDisabled');
        setTimeout( () => 
        {
        if (document.activeElement !== X.textEditor()) {
            X.textEditor().focus()
        }
        },20);
      }
    }
  }
 
   if ( lastClickEl.classList.contains('Preferences__button') )
   {
     console.log("menu pref click");
     showPreferenceContentWindow();
   }
   
    if (lastClickEl.classList.contains('module-ConversationHeader__button--search') || lastClickEl.classList.contains('module-Button--icon--search') )
        showchatlist();
  
 
  
}); 

window.addEventListener("click", function() {
  //Backup Back button
  setTimeout( () => {
  backupBackButton();
  },400);
})

//-----------------------------------------------------------------------------
//         Function to add a back button in chat view header
//              To go back to main chat list view
//----------------------------------------------------------------------------
function addBackButtonToChatView(){

    addCss(".back_button span { display:block; height: 100%; width: 100%;}.back_button {  z-index:200; width:37px; height:45px; } html[dir] .back_button { border-radius:50%; } html[dir=ltr] .back_button { right:11px } html[dir=rtl] .back_button { left:11px } .back_button path { fill:var(--panel-header-icon); fill-opacity:1 } .svg_back { transform: rotate(90deg); height: 100%;}");
    
    var newHTML         = document.createElement('div');
    newHTML.className += "back_button";
    newHTML.style = "";
    newHTML.addEventListener("click", showchatlist);
    newHTML.innerHTML   = "<span data-icon='left' id='back_button' ><svg class='svg_back' id='Layer_1' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 21 21' width='21' height='21'><path fill='#000000' fill-opacity='1' d='M4.8 6.1l5.7 5.7 5.7-5.7 1.6 1.6-7.3 7.2-7.3-7.2 1.6-1.6z'></path></svg></span>";

    if (! X.chatHeader().querySelector('#back_button') )
        X.chatHeader().prepend(newHTML);
}

function addBackButtonToPreferences(){

    addCss(".back_button_pref span { display:block; height: 100%; width: 100%;}.back_button_pref {  z-index:200; width:37px; height:45px; } html[dir] .back_button_pref { border-radius:50%; margin-left: 3vw;} html[dir=ltr] .back_button_pref { right:11px } html[dir=rtl] .back_button_pref { left:11px } .back_button_pref path { fill:var(--panel-header-icon); fill-opacity:1 } .svg_back { transform: rotate(90deg); height: 100%;}");
    
    var newHTML         = document.createElement('div');
    newHTML.className += "back_button_pref";
    newHTML.style = "";
    newHTML.addEventListener("click", showchatlist);
    newHTML.innerHTML   = "<span data-icon='left' id='back_button_pref' ><svg class='svg_back' id='Layer_1' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 21 21' width='21' height='21'><path fill='#000000' fill-opacity='1' d='M4.8 6.1l5.7 5.7 5.7-5.7 1.6 1.6-7.3 7.2-7.3-7.2 1.6-1.6z'></path></svg></span>";

    if (! X.preferenceContentHeader().querySelector('#back_button_pref') )
        X.preferenceContentHeader().prepend(newHTML);
}



//-----------------------------------------------------------------------------
//         Function to show main chat list view
//----------------------------------------------------------------------------
function showchatlist(){
  
 // if ( X.leftMenu().style.display != 'none')
 //   toggleLeftMenu()
  
  setTimeout( () => {
    addHiddenCSS()
  },500);
  //Slide back Chatlist panel to main view  
  X.chatList().style.position= 'absolute';
  X.chatList().style.transform = 'translateX(0)';
  X.chatList().style.transition= "transform 0.25s ease-in-out;";
  X.chatList().style.willChange= "transform";  
  X.chatList().width="100%"
  X.chatList().minWidth="100%"
  X.chatList().style.zIndex = "1000"
  X.chatList().style.minWidth= '100%';
  X.buttonTogleLeftMenuHelper().style.display="none";
  
  document.querySelectorAll(".contenteditableDisabled").forEach(el2 => {
    el2.classList.remove('contenteditableDisabled') 
    el2.setAttribute("contenteditable", "true");
  });
}

function showchatWindow(){
  //Make sure to unfocus any focused élément of previous view
   document.activeElement.blur();
   
   X.chatWindow().style.position=""
   X.chatWindow().style.left=""
   removeHiddenCSS();
   
   //Slide Chatlist panel to the left
   X.chatList().style.position= 'absolute'; 
   void X.chatList().offsetWidth;
   if (document.querySelector(".NavTabs--collapsed"))
      X.chatList().style.transform = 'translateX(-100%)';
    else
      X.chatList().style.transform = 'translateX(-125%)';      
   X.chatList().style.transition= "transform 0.25s ease-in-out !important";
   X.chatList().style.willChange= "transform";
   X.chatList().style.minWidth= '100%';
   
  //Hide left menu (in case it was oppened)
    addBackButtonToChatViewWithTimeout();
}

function showPreferenceContentWindow(){
  //Make sure to unfocus any focused élément of previous view
   document.activeElement.blur();
   
   X.preferenceContentWindow().style.position=""
   X.preferenceContentWindow().style.left=""
   removeHiddenCSS();
   
   //Slide Chatlist panel to the left
   X.chatList().style.position= 'absolute'; 
   void X.chatList().offsetWidth;
   if (document.querySelector(".NavTabs--collapsed"))
      X.chatList().style.transform = 'translateX(-100%)';
   else
      X.chatList().style.transform = 'translateX(-125%)'; 
   X.chatList().style.transition= "transform 0.25s ease-in-out !important";
   X.chatList().style.willChange= "transform";
   X.chatList().style.minWidth= '100%';
   
  //Hide left menu (in case it was oppened)
  addBackButtonToPreferences();
}

function addBackButtonToChatViewWithTimeout()
{
      //Add back Button
    setTimeout(() => {
        addBackButtonToChatView();
    }, 20);

    setTimeout(() => {
    addBackButtonToChatView();
    }, 500);    
    
    setTimeout(() => {
    addBackButtonToChatView();
    }, 1500); 
  
}

function backupBackButton()
{
 if (X.chatList().style.transform== "translateX(-125%)" || X.chatList().style.transform== "translateX(-100%)") {
  if (  X.chatHeader() )
  {
    if (! X.chatHeader().querySelector('#back_button')  )
    {
    addBackButtonToChatView();  
    }
  }
  else if ( ! X.chatWindow().querySelector(".ConversationPanel__header__back-button") )
  {
    showchatlist()
  }
} 
}

//-----------------------------------------------------------------------------
//          Avoid opening Message menu unwillingly when scrolling
//----------------------------------------------------------------------------

var allowOpeningMessageMenu=0;
function intercept(e) {
    const target = e.target.closest('.module-message__buttons__menu');

    if (target && allowOpeningMessageMenu == 0) {
        console.log("cursor!!!");
        allowOpeningMessageMenu=1;
        e.stopPropagation();
    }
    allowOpeningMessageMenu=0;
}

document.addEventListener('pointerdown', intercept, true);

document.addEventListener('click', function (event) {
  
  const target = event.target.closest('.module-message__buttons__menu');
 
  if (target) {
    console.log("click!!!");
    allowOpeningMessageMenu=1;
    const pointerEvent = new PointerEvent('pointerdown', {
      bubbles: true,
      cancelable: true,
      pointerType: 'mouse', // ou 'touch' si besoin
      isPrimary: true
    });

    target.dispatchEvent(pointerEvent);
  }
});
