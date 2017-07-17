/*
	Title: Modelling cross origin requests and preventing them with CORP
	Author: Shubh Maheshwari

	Description: The predicates in this model shows: 
	1. User authentication to a genuine server.
	2. An instance of malicious cross-origin request attack after the User authenticated.
	3. How CORP stops a malicious cross-origin request attack 
*/

/************************
		MODULES
************************/
open util/ordering[State] as ord

/*****************************
				CORP
*****************************/
abstract sig CORP{
	browser: one Browser
}

abstract sig RequestPath{}
	lone sig SensitivePath extends RequestPath{} 
	lone sig NonSensitivePath extends RequestPath{} 

/****************************
				HTTP TRANSACTION
****************************/
one abstract sig HTTPTransaction{}
abstract sig HTTPEventInitiator {}

abstract sig TransType {}
	one sig StartAuth  extends TransType {}
	one sig IdPAuthentication extends TransType {}
	one sig SPAuthentication extends TransType {}
	one sig CORA extends TransType{}

/**************************
				STATUS
***************************/

one sig Status {}

/****************************
				BROWSER
****************************/

one sig Browser{
	tab: set BrowserTab,
	corp:one CORP
}

sig BrowserTab {
	tabOrigin: Server,
	elements: some Element
}

/*****************************
				SERVERS
*****************************/

abstract sig Server {}

	lone sig IdentityProvider extends Server { }
	lone sig ServiceProvider extends Server { } 
	lone sig AttackerServer extends Server {}

/****************************
					ELEMENTS
****************************/
sig Redirection extends HTTPEventInitiator {}

abstract sig Element extends HTTPEventInitiator {}

	sig URLAddressBar extends Element {}
	abstract sig HTMLElement extends Element{}

		abstract sig ActiveHTMLElement extends HTMLElement {}
		sig ScriptElement, ImageElement, CssElement, Iframe, Hyperlink, Form extends ActiveHTMLElement {}

/***************************
				STATE
***************************/

sig State{

	//Relations on the Status of the STATUS
	transType:HTTPTransaction -> one TransType,
	token: HTTPTransaction -> one Int,

	http_path:HTTPTransaction -> lone RequestPath,
	req_from: HTTPEventInitiator one ->lone HTTPTransaction,
	req_to: HTTPTransaction -> one Server,
	resp_from: Server ->lone  HTTPTransaction,
	resp_to: HTTPTransaction ->one BrowserTab,

	//Relations on the Status of the STATUS
	IDP: Status -> one Int,
	SP:Status -> one Int,
	authentication_Status :Status ->  one Int,
	CORA:Status -> one Int,

	//Corp Relations
	origin : CORP -> lone Server ,
	path: CORP -> lone RequestPath ,
	how:CORP -> lone HTTPEventInitiator

}
{
	//Necessary facts on State
	
	//No orphan elements
	no ((Element + URLAddressBar) - BrowserTab.elements )
	no (BrowserTab - Browser.tab)
	no (CORP - Browser.corp)
	//no (RequestPath - HTTPTransaction.http_path - CORP.path)

	//Inverse Relations	
	req_to=~resp_from
	corp=~browser

	//Transaction Rules
	HTTPTransaction.req_to = ServiceProvider or 
	HTTPTransaction.req_to = IdentityProvider
	BrowserTab.tabOrigin = (ServiceProvider  + AttackerServer)
	HTTPTransaction.token = 2

	//Transaction Constraint: req_from and resp_to
	all tab:BrowserTab, element: tab.elements | 
		element.req_from = HTTPTransaction
	=>
		HTTPTransaction.resp_to = tab
}

fact NoSameElement { 
	all tab,tab':BrowserTab,element : Element |
		element in tab.elements and element in tab'.elements => tab = tab' 
}

fact Authenticated {all s:State |
	Status.(s.IDP) =1 and Status.(s.SP) =1 
	=>
		 Status.(s.authentication_Status) =1
	else 
		Status.(s.authentication_Status) =0 
}    

let s0 = ord/first
let s1=ord/next[s0]
let s2=ord/next[s1]
let s3=ord/next[s2]

fact InitialState{

	//Transaction Reactions
	HTTPTransaction.(s0.transType) = StartAuth 
	(s0.req_from).HTTPTransaction = URLAddressBar 
	(HTTPTransaction.(s0.resp_to)).tabOrigin = ServiceProvider   
	HTTPTransaction.(s0.req_to) = ServiceProvider 

	//Initial Status
	Status.(s0.IDP) = 0 
	Status.(s0.SP) =0
	Status.(s0.CORA)=0 
	Status.(s0.authentication_Status) =0 

}

/****************************
			FUNCTIONS
****************************/

//Takes a  state and returns it and every state after it 
	fun allNext[s:State] :set State {s.*(ord/next)}

/*****************************
		PREDICATE
******************************/

pred corpCheck [ s: State,sTab:BrowserTab, sv: Server, ev: HTTPEventInitiator, pt: RequestPath ] { 
	one s.http_path &&
	CORP.(s.how)= ev && 	
	CORP.(s.path) = pt &&
	CORP.(s.origin) = sv &&

	(s.req_from).HTTPTransaction = ev && 
	HTTPTransaction.(s.http_path) = pt &&
	sTab.tabOrigin = sv 
}

pred corpCompliantTransaction[sv:Server,ev:HTTPEventInitiator, pt: RequestPath]{
all s:State| 
	let sTab= HTTPTransaction.(s.resp_to) | { 
	sTab.tabOrigin != HTTPTransaction.(s.req_to) &&
	HTTPTransaction.(s.req_to) = ServiceProvider  
	=> 
		corpCheck[s,sTab,sv,ev,pt]
	else
		no s.how &&	
		no s.path &&
		no s.http_path &&
		no s.origin	
	}
}

pred restrictElementsWithCORP {
	some ev: HTTPEventInitiator {
		corpCompliantTransaction [AttackerServer, ev, NonSensitivePath]
	}
}

pred restrictImagesWithCORP {
	corpCompliantTransaction [ AttackerServer, ImageElement, NonSensitivePath ]
}
pred restrictScriptsWithCORP {
	corpCompliantTransaction [ AttackerServer, ImageElement, NonSensitivePath ]
}

pred IdentityProviderAuthentication{let s=s1 |
	HTTPTransaction.(s.transType) = IdPAuthentication &&
	HTTPTransaction.(s.req_to) = IdentityProvider &&
	(HTTPTransaction.(s.resp_to)).tabOrigin = ServiceProvider  &&
	(s.req_from).HTTPTransaction in Form &&

	Status.(allNext[s].IDP) =1 &&
	restrictElementsWithCORP
}


pred ServiceProviderAuthentication{let s=s2 |

	IdentityProviderAuthentication&&

	HTTPTransaction.(s.transType) = SPAuthentication &&
	HTTPTransaction.(s.req_to) = ServiceProvider &&
	(HTTPTransaction.(s.resp_to)).tabOrigin = ServiceProvider  &&
	(s.req_from).HTTPTransaction = Redirection &&

	Status.(ord/prevs[s].SP)=0 &&
	Status.(allNext[s].SP) =1
}

pred Authenticated {
	let s=ord/nexts[s2] |
	ServiceProviderAuthentication &&
	Status.(s.authentication_Status) = 1 
} 

pred CrossOriginAttack { let s=s3| 
	Authenticated &&
	restrictImagesWithCORP &&
	HTTPTransaction.(s.transType) = CORA &&
	HTTPTransaction.(s.req_to) = ServiceProvider &&
	(HTTPTransaction.(s.resp_to)).tabOrigin = AttackerServer  &&
	(s.req_from).HTTPTransaction in HTMLElement &&
	HTTPTransaction.(s.http_path) = NonSensitivePath &&

	Status.(ord/prevs[s].CORA)=0 &&
	Status.(allNext[s].CORA) = 1
} 


pred maliciousCrossOriginAttackWithImage {
	CrossOriginAttack 
	HTTPTransaction.(s3.http_path) = SensitivePath
}

run IdentityProviderAuthentication for 2 but  exactly 2 BrowserTab
run ServiceProviderAuthentication for 3 but  exactly 1 BrowserTab
run Authenticated for 4 but  exactly 2 BrowserTab
run  CrossOriginAttack for 8 but exactly 2 BrowserTab,exactly 4 State,2 HTMLElement
run  maliciousCrossOriginAttackWithImage for 20
