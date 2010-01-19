function listmembers(target) {
	var members = [];
	for (var method in target) {
    members.push(method);
	};
	return members.sort();
}