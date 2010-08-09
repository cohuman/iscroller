var events = [];

function addEvent(event){
	events.push(event);
}

function addEventFunction(message){
	return function(){
		addEvent(message)
	}
};