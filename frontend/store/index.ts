import { ActionTree, MutationTree } from 'vuex';
import { Task } from 'taskwarrior-lib';
import { getAccessorType } from 'typed-vuex';

export const state = () => ({
	tasks: [] as Task[]
});

export type RootState = ReturnType<typeof state>;

export const mutations: MutationTree<RootState> = {
	setTasks(state, tasks: Task[]) {
		state.tasks = tasks;
	}
};

export const actions: ActionTree<RootState, RootState> = {
	async fetchTasks(context) {
		const tasks: Task[] = await this.$axios.$get('/api/tasks');
		context.commit('setTasks', tasks);
	},

	async deleteTasks(context, tasks: Task[]) {
		await this.$axios.$delete('/api/tasks', {
			params: { tasks: tasks.map(task => task.uuid) }
		});
		// Refresh
		await context.dispatch('fetchTasks');
	}
};

export const accessorType = getAccessorType({
	state,
	mutations,
	actions
});