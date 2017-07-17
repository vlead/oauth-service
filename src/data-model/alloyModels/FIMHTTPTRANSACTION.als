/*
	Title: Modelling cross origin requests and preventing them with CORP
	Author: Shubh Maheshwari

	Description: The predicates in this model shows: 
	1. User authentication to a genuine server.
	2. An instance of malicious cross-origin request attack after the User authenticated.
*/

/************************
		MODULES
************************/

open util/ordering[State] as ord

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
	tab: set BrowserTab
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

	// Relations on HTTP transaction
	transType : HTTPTransaction -> one TransType,
	token : HTTPTransaction -> one Int,

	req_from : HTTPEventInitiator one -> lone HTTPTransaction,
	req_to : HTTPTransaction -> one Server,
	resp_from : Server -> lone HTTPTransaction,
	resp_to : HTTPTransaction -> one BrowserTab,

	//Relations on the Status of the STATUS
	IDP : Status -> one Int,
	SP : Status -> one Int,
	authentication_Status : Status -> one Int,
	CORA : Status -> one Int
}
{
	//Necessary facts on State

	//No orphan elements
	no (Element + URLAddressBar - BrowserTab.elements)
	no (BrowserTab - Browser.tab)

	//Inverse Relations
	req_to=~resp_from
	
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

fact NoSameElement{ all tab, tab': BrowserTab, element : Element |
	element in tab.elements and element in tab'.elements => tab = tab' }

let s0 = ord/first
let s1=ord/next[s0]
let s2=ord/next[s1]
let s3=ord/next[s2]

fact InitialState{
	Status.(s0.IDP) = 0 
	Status.(s0.SP) =0
	Status.(s0.CORA)=0 
	Status.(s0.authentication_Status) =0 

	HTTPTransaction.(s0.transType) = StartAuth 
	(s0.req_from).HTTPTransaction = URLAddressBar 
	(HTTPTransaction.(s0.resp_to)).tabOrigin = ServiceProvider   
	HTTPTransaction.(s0.req_to) = ServiceProvider 
}

fact Authenticated { all s:State |
	Status.(s.IDP) =1 and Status.(s.SP) =1 
	=> 
		Status.(s.authentication_Status) =1
	else 
		Status.(s.authentication_Status) =0 
}    

/****************************
			FUNCTIONS
****************************/

//Takes a  state and returns it and every state after it 
	fun allNext[s:State] :set State {s.*(ord/next)}

/*****************************
		PREDICATE
******************************/


pred IdentityProviderAuthentication{let s=s1 |
	HTTPTransaction.(s.transType) = IdPAuthentication &&
	HTTPTransaction.(s.req_to) = IdentityProvider &&
	(HTTPTransaction.(s.resp_to)).tabOrigin = ServiceProvider  &&
	(s.req_from).HTTPTransaction in Form &&

	Status.(allNext[s].IDP) =1 
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
	HTTPTransaction.(s.transType) = CORA &&
	HTTPTransaction.(s.req_to) = ServiceProvider &&
	(HTTPTransaction.(s.resp_to)).tabOrigin = AttackerServer  &&
	(s.req_from).HTTPTransaction in HTMLElement &&

	Status.(ord/prevs[s].CORA)=0 &&
	Status.(allNext[s].CORA) = 1 
} 

run IdentityProviderAuthentication for 2
run ServiceProviderAuthentication for 3

run Authenticated for 6
run  CrossOriginAttack for 8 but exactly 2 BrowserTab,exactly 4 State,2 HTMLElement


